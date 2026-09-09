enum ExerciseSource { builtIn, custom }

class ExerciseProject {
  const ExerciseProject({required this.id, required this.name, required this.source, required this.createdAt});

  final String id;
  final String name;
  final ExerciseSource source;
  final DateTime createdAt;

  bool get isBuiltIn => source == ExerciseSource.builtIn;

  ExerciseProject copyWith({String? name}) => ExerciseProject(
    id: id, name: name ?? this.name, source: source, createdAt: createdAt,
  );

  Map<String, Object?> toJson() => {
    'id': id, 'name': name, 'source': source.name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ExerciseProject.fromJson(Map<String, dynamic> json) => ExerciseProject(
    id: json['id'] as String,
    name: json['name'] as String,
    source: ExerciseSource.values.byName(json['source'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

/// Seed data written only when its id is absent. Afterwards the database is
/// canonical, so a user-edited built-in project is never overwritten.
const builtInExerciseProjects = [
  ('builtin.push-up', '俯卧撑'), ('builtin.squat', '深蹲'),
  ('builtin.pull-up', '引体向上'), ('builtin.running', '跑步'),
  ('builtin.stairs', '爬楼梯'), ('builtin.jackknife-push-up', '折刀俯卧撑'),
  ('builtin.plank', '平板支撑'),
];
