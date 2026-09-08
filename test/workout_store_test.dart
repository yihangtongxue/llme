import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:llme/data/workout.dart';
import 'package:llme/data/workout_store.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast/sembast_memory.dart';

Workout sample(
  String id,
  DateTime date, {
  String exercise = '俯卧撑',
  List<int> reps = const [12, 12, 12],
  String? energy,
}) => Workout(
  id: id,
  date: dayKey(date),
  createdAt: date,
  exercise: exercise,
  reps: reps,
  energy: energy,
);

void main() {
  test(
    'records, custom projects and daily energy survive a real database reopen',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'llme-persistence-',
      );
      final path = '${directory.path}/test.db';
      final now = DateTime(2026, 9, 8, 12);
      final db = await databaseFactoryIo.openDatabase(path);
      final store = WorkoutStore(db, clock: () => now);
      await store.load();
      await store.addExercise('卷腹');
      await store.save(
        sample('a', now, exercise: '卷腹', reps: [12, 10, 8], energy: '中'),
      );
      store.dispose();
      await db.close();

      final reopened = await databaseFactoryIo.openDatabase(path);
      final restored = WorkoutStore(reopened, clock: () => now);
      await restored.load();
      expect(restored.records.single.reps, [12, 10, 8]);
      expect(restored.exercises, contains('卷腹'));
      expect(restored.latest('卷腹')!.total, 30);
      expect(restored.energyOn(now), '中');
      expect(restored.energyOn(shiftDay(now, 1)), isNull);
      restored.dispose();
      await reopened.close();
      await directory.delete(recursive: true);
    },
  );

  test(
    'same-day entries count once; editing, removal and undo update all stats',
    () async {
      final db = await databaseFactoryMemory.openDatabase('stats');
      final now = DateTime(2026, 9, 8);
      final store = WorkoutStore(db, clock: () => now);
      await store.load();
      final original = sample('a', shiftDay(now, -1));
      await store.save(original);
      await store.save(sample('b', shiftDay(now, -1), exercise: '深蹲'));
      await store.save(sample('c', shiftDay(now, -2)));
      expect(store.daysBetween(weekStart(now), shiftDay(now, 1)), 1);
      expect(
        store.streak,
        2,
      ); // Today can be blank without erasing yesterday's streak.
      await store.save(sample('a', shiftDay(now, -1), reps: [12, 10, 8]));
      expect(store.records.length, 3);
      expect(store.records.singleWhere((r) => r.id == 'a').total, 30);
      await store.remove('a');
      expect(store.onDate(shiftDay(now, -1)).length, 1);
      await store.save(original);
      expect(store.records.singleWhere((r) => r.id == 'a').total, 36);
      await store.save(sample('today', now));
      expect(store.streak, 3);
      expect(store.daysBetween(weekStart(now), shiftDay(now, 1)), 2);
      store.dispose();
      await db.close();
    },
  );

  test(
    'invalid input and failed persistence do not alter published records',
    () async {
      final db = await databaseFactoryMemory.openDatabase('failure');
      final now = DateTime(2026, 9, 8);
      final store = WorkoutStore(db, clock: () => now);
      await store.load();
      await store.save(sample('a', now));
      expect(() => sample('bad', now, reps: [0]), throwsFormatException);
      await expectLater(store.addExercise('俯卧撑'), throwsFormatException);
      await expectLater(store.addExercise('   '), throwsFormatException);
      await db.close();
      await expectLater(store.remove('a'), throwsA(anything));
      expect(store.records.single.id, 'a');
      expect(store.busy, isFalse);
      store.dispose();
    },
  );

  test('calendar arithmetic handles month/year boundaries', () {
    expect(dayKey(shiftDay(DateTime(2026, 1, 1), -1)), '2025-12-31');
    expect(dayKey(weekStart(DateTime(2026, 1, 1))), '2025-12-29');
    expect(dayKey(shiftDay(DateTime(2024, 3, 1), -1)), '2024-02-29');
  });
}
