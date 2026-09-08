import 'package:flutter/foundation.dart';
import 'package:sembast/sembast.dart';

import 'workout.dart';

class WorkoutStore extends ChangeNotifier {
  WorkoutStore(this.database, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;

  final Database database;
  final DateTime Function() clock;
  final _state = stringMapStoreFactory.store('app').record('state');
  List<Workout> _records = [];
  List<String> _custom = [];
  Map<String, String> _energies = {};
  bool busy = false;
  String? _observedDay;

  List<Workout> get records => List.unmodifiable(_records);
  DateTime get today => dayOnly(clock());
  String? energyOn(DateTime date) => _energies[dayKey(date)];

  Future<void> load() async {
    final state = await _state.get(database);
    if (state != null) {
      if (state['version'] != 1) throw const FormatException('不支持的数据版本');
      final records = (state['records'] as List)
          .map(
            (value) =>
                Workout.fromJson(Map<String, dynamic>.from(value as Map)),
          )
          .toList();
      final custom = (state['custom'] as List).cast<String>();
      final energies = Map<String, String>.from(state['energies'] as Map);
      _records = records;
      _custom = custom;
      _energies = energies;
    }
    _sort();
    _observedDay = dayKey(today);
    notifyListeners();
  }

  void refreshDay() {
    if (_observedDay != dayKey(today)) {
      _observedDay = dayKey(today);
      notifyListeners();
    }
  }

  List<String> get exercises {
    final names = ['俯卧撑', '深蹲', '引体向上', ..._custom];
    final counts = <String, int>{};
    for (final r in _records) {
      counts.update(r.exercise, (n) => n + 1, ifAbsent: () => 1);
    }
    final order = {for (var i = 0; i < names.length; i++) names[i]: i};
    names.sort((a, b) {
      final count = (counts[b] ?? 0).compareTo(counts[a] ?? 0);
      return count != 0 ? count : order[a]!.compareTo(order[b]!);
    });
    return names;
  }

  Workout? latest(String exercise) {
    for (final record in _records) {
      if (record.exercise == exercise) return record;
    }
    return null;
  }

  List<Workout> onDate(DateTime date) =>
      _records.where((r) => r.date == dayKey(date)).toList();

  List<Workout> between(DateTime start, DateTime end, {String? exercise}) =>
      _records
          .where(
            (r) =>
                r.date.compareTo(dayKey(start)) >= 0 &&
                r.date.compareTo(dayKey(end)) < 0 &&
                (exercise == null || r.exercise == exercise),
          )
          .toList();

  int daysBetween(DateTime start, DateTime end) =>
      between(start, end).map((r) => r.date).toSet().length;

  int get streak {
    final days = _records.map((r) => r.date).toSet();
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

  Future<void> _commit(
    List<Workout> records,
    List<String> custom,
    Map<String, String> energies,
  ) async {
    if (busy) throw StateError('正在保存，请稍后');
    busy = true;
    notifyListeners();
    try {
      await database.transaction((txn) async {
        await _state.put(txn, {
          'version': 1,
          'records': records.map((r) => r.toJson()).toList(),
          'custom': custom,
          'energies': energies,
        });
      });
      // Publish only after the transaction succeeds.
      _records = records;
      _custom = custom;
      _energies = energies;
      _sort();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> save(Workout workout) async {
    final records = _records.where((r) => r.id != workout.id).toList()
      ..add(workout);
    final energies = Map<String, String>.from(_energies);
    if (workout.energy != null) energies[workout.date] = workout.energy!;
    await _commit(records, List.of(_custom), energies);
  }

  Future<void> remove(String id) => _commit(
    _records.where((r) => r.id != id).toList(),
    List.of(_custom),
    Map.of(_energies),
  );

  Future<void> addExercise(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 20) {
      throw const FormatException('项目名称需为 1–20 个字');
    }
    if (exercises.any((e) => e.toLowerCase() == trimmed.toLowerCase())) {
      throw const FormatException('这个项目已存在');
    }
    await _commit(List.of(_records), [..._custom, trimmed], Map.of(_energies));
  }
}
