String dayKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

DateTime dayOnly(DateTime date) => DateTime(date.year, date.month, date.day);
DateTime shiftDay(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);
DateTime weekStart(DateTime date) => shiftDay(dayOnly(date), 1 - date.weekday);

class Workout {
  Workout({
    required this.id,
    required this.date,
    required this.createdAt,
    required this.exercise,
    required List<int> reps,
    this.durationMinutes,
    this.energy,
  }) : reps = List.unmodifiable(reps) {
    if (exercise.trim().isEmpty ||
        exercise.length > 20 ||
        reps.isEmpty ||
        reps.length > 30 ||
        reps.any((n) => n < 1 || n > 999) ||
        (durationMinutes != null &&
            (durationMinutes! < 1 || durationMinutes! > 999)) ||
        (energy != null && !['低', '中', '高'].contains(energy))) {
      throw const FormatException('训练记录不合法');
    }
    DateTime.parse(date);
  }

  final String id;
  final String date;
  final DateTime createdAt;
  final String exercise;
  final List<int> reps;
  final int? durationMinutes;
  final String? energy;

  bool get isTimed => durationMinutes != null;
  int get total => durationMinutes ?? reps.fold(0, (sum, n) => sum + n);
  bool get uniform => reps.every((n) => n == reps.first);
  String get summary => isTimed
      ? '$durationMinutes 分钟'
      : uniform
      ? '${reps.length} 组 × ${reps.first} 次'
      : '${reps.length} 组 · ${reps.join(' / ')} 次';

  Map<String, Object?> toJson() => {
    'id': id,
    'date': date,
    'createdAt': createdAt.toIso8601String(),
    'exercise': exercise,
    'reps': reps,
    'durationMinutes': durationMinutes,
    'energy': energy,
  };

  factory Workout.fromJson(Map<String, dynamic> json) => Workout(
    id: json['id'] as String,
    date: json['date'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    exercise: json['exercise'] as String,
    reps: (json['reps'] as List).cast<int>(),
    durationMinutes: json['durationMinutes'] as int?,
    energy: json['energy'] as String?,
  );
}
