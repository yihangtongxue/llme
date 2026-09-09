import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:sembast/sembast.dart';

import 'exercise_project.dart';
import 'workout.dart';

class WorkoutStore extends ChangeNotifier {
  WorkoutStore(this.database, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;

  final Database database;
  final DateTime Function() clock;
  final _state = stringMapStoreFactory.store('app').record('state');
  final _projects = stringMapStoreFactory.store('exercise_projects');
  List<Workout> _records = [];
  List<ExerciseProject> _exerciseProjects = [];
  Map<String, String> _energies = {};
  bool busy = false;
  String? _observedDay;

  List<Workout> get records => List.unmodifiable(_records);
  List<ExerciseProject> get exerciseProjects => List.unmodifiable(_exerciseProjects);
  List<String> get exercises => _exerciseProjects.map((project) => project.name).toList();
  DateTime get today => dayOnly(clock());
  String? energyOn(DateTime date) => _energies[dayKey(date)];

  Future<void> load() async {
    final state = await _state.get(database);
    var legacyCustom = const <String>[];
    if (state != null) {
      final version = state['version'];
      if (version != 1 && version != 2) throw const FormatException('不支持的数据版本');
      _records = (state['records'] as List)
          .map((value) => Workout.fromJson(Map<String, dynamic>.from(value as Map)))
          .toList();
      _energies = Map<String, String>.from(state['energies'] as Map);
      if (version == 1) legacyCustom = (state['custom'] as List? ?? const []).cast<String>();
    }
    await _loadProjects(legacyCustom);
    if (state != null && state['version'] == 1) {
      await _state.put(database, {
        'version': 2,
        'records': _records.map((record) => record.toJson()).toList(),
        'energies': _energies,
      });
    }
    _sort();
    _observedDay = dayKey(today);
    notifyListeners();
  }

  Future<void> _loadProjects(List<String> legacyCustom) async {
    final saved = await _projects.find(database);
    final projects = <ExerciseProject>[
      for (final record in saved)
        ExerciseProject.fromJson(Map<String, dynamic>.from(record.value)),
    ];
    final ids = projects.map((project) => project.id).toSet();
    final additions = <ExerciseProject>[];
    for (final (id, name) in builtInExerciseProjects) {
      if (ids.add(id)) additions.add(ExerciseProject(
        id: id, name: name, source: ExerciseSource.builtIn, createdAt: DateTime(2026),
      ));
    }
    for (final name in legacyCustom) {
      final id = 'legacy.${name.hashCode}';
      if (ids.add(id)) additions.add(ExerciseProject(
        id: id, name: name, source: ExerciseSource.custom, createdAt: DateTime(2026),
      ));
    }
    if (additions.isNotEmpty) {
      await database.transaction((txn) async {
        for (final project in additions) {
          await _projects.record(project.id).put(txn, project.toJson());
        }
      });
    }
    _exerciseProjects = [...projects, ...additions]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  List<ExerciseProject> get projectsByUsage {
    final projects = List.of(_exerciseProjects);
    final counts = <String, int>{};
    for (final record in _records) {
      counts.update(record.exercise, (count) => count + 1, ifAbsent: () => 1);
    }
    projects.sort((a, b) {
      final count = (counts[b.name] ?? 0).compareTo(counts[a.name] ?? 0);
      return count != 0 ? count : a.createdAt.compareTo(b.createdAt);
    });
    return projects;
  }

  void refreshDay() {
    if (_observedDay != dayKey(today)) {
      _observedDay = dayKey(today);
      notifyListeners();
    }
  }

  Workout? latest(String exercise) {
    for (final record in _records) {
      if (record.exercise == exercise) return record;
    }
    return null;
  }

  List<Workout> onDate(DateTime date) =>
      _records.where((record) => record.date == dayKey(date)).toList();

  List<Workout> between(DateTime start, DateTime end, {String? exercise}) =>
      _records.where((record) =>
        record.date.compareTo(dayKey(start)) >= 0 &&
        record.date.compareTo(dayKey(end)) < 0 &&
        (exercise == null || record.exercise == exercise),
      ).toList();

  int daysBetween(DateTime start, DateTime end) =>
      between(start, end).map((record) => record.date).toSet().length;

  int get streak {
    final days = _records.map((record) => record.date).toSet();
    var date = today;
    if (!days.contains(dayKey(date))) date = shiftDay(date, -1);
    var result = 0;
    while (days.contains(dayKey(date))) {
      result++;
      date = shiftDay(date, -1);
    }
    return result;
  }

  void _sort() => _records.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Future<void> _commit(List<Workout> records, Map<String, String> energies) async {
    if (busy) throw StateError('正在保存，请稍后');
    busy = true;
    notifyListeners();
    try {
      await _state.put(database, {
        'version': 2,
        'records': records.map((record) => record.toJson()).toList(),
        'energies': energies,
      });
      _records = records;
      _energies = energies;
      _sort();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> save(Workout workout) async {
    final records = _records.where((record) => record.id != workout.id).toList()
      ..add(workout);
    final energies = Map<String, String>.from(_energies);
    if (workout.energy != null) energies[workout.date] = workout.energy!;
    await _commit(records, energies);
  }

  Future<void> remove(String id) => _commit(
    _records.where((record) => record.id != id).toList(), Map.of(_energies),
  );

  Future<void> addExercise(String name) async {
    final trimmed = _validatedName(name);
    await _saveProject(ExerciseProject(
      // A 32-bit left shift evaluates to zero on the JavaScript backend.
      id: 'custom.${DateTime.now().microsecondsSinceEpoch}.${Random().nextInt(0x100000000)}',
      name: trimmed,
      source: ExerciseSource.custom,
      createdAt: clock(),
    ));
  }

  Future<void> renameExercise(ExerciseProject project, String name) {
    if (project.isBuiltIn) {
      throw const FormatException('内置项目不能修改');
    }
    return _saveProject(project.copyWith(name: _validatedName(name)));
  }

  Future<void> deleteExercise(ExerciseProject project) async {
    if (project.isBuiltIn) throw const FormatException('内置项目不能删除');
    if (busy) throw StateError('正在保存，请稍后');
    busy = true;
    notifyListeners();
    try {
      await _projects.record(project.id).delete(database);
      _exerciseProjects.removeWhere((item) => item.id == project.id);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  String _validatedName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 20) {
      throw const FormatException('项目名称需为 1–20 个字');
    }
    return trimmed;
  }

  Future<void> _saveProject(ExerciseProject project) async {
    if (busy) throw StateError('正在保存，请稍后');
    busy = true;
    notifyListeners();
    try {
      await _projects.record(project.id).put(database, project.toJson());
      final index = _exerciseProjects.indexWhere((item) => item.id == project.id);
      if (index == -1) {
        _exerciseProjects.add(project);
      } else {
        _exerciseProjects[index] = project;
      }
      _exerciseProjects.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
