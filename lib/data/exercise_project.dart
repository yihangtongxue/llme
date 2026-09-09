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

/// Seed data written only when its id is absent.
const builtInExerciseProjects = [
  ('builtin.standing-arm-circles', '站姿直臂绕肩'),
  ('builtin.alternating-shoulder-taps', '交替摸肩'),
  ('builtin.waist-push-up', '腰间俯卧撑'),
  ('builtin.shoulder-push-up', '冲肩俯卧撑'),
  ('builtin.jackknife-push-up', '折刀俯卧撑'),
  ('builtin.chest-cross-stretch', '胸前交叉拉伸'),
];
