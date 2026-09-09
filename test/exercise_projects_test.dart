import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:llme/data/workout_store.dart';
import 'package:llme/features/profile/exercise_projects_page.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  // Keep this suite free of dart:io so it can also catch Web-only ID failures.
  test('same-named custom projects have distinct IDs and persist', () async {
    final db = await databaseFactoryMemory.openDatabase('project-ids');
    final store = WorkoutStore(db);
    final restored = WorkoutStore(db);
    try {
      await store.load();
      await store.addExercise('折刀俯卧撑');
      await store.addExercise('折刀俯卧撑');
      await restored.load();
      final projects = restored.exerciseProjects
          .where((project) => project.name == '折刀俯卧撑')
          .toList();
      expect(projects.length, 3);
      expect(projects.map((project) => project.id).toSet().length, 3);
      expect(projects.where((project) => project.isBuiltIn).length, 1);
    } finally {
      store.dispose();
      restored.dispose();
      await db.close();
    }
  });

  testWidgets('create, rename and cancel survive dialog exit animations', (
    tester,
  ) async {
    final db = (await tester.runAsync(
      () => databaseFactoryMemory.openDatabase('project-dialog'),
    ))!;
    final store = WorkoutStore(db);
    await tester.runAsync(store.load);
    try {
      await tester.pumpWidget(
        MaterialApp(home: ExerciseProjectsPage(store: store)),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('重命名'), findsNothing);
      expect(find.byTooltip('删除'), findsNothing);

      await tester.tap(find.text('新增项目'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '卷腹');
      await tester.tap(find.text('保存'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(store.exercises, contains('卷腹'));
      expect(tester.takeException(), isNull);

      final rename = find.byTooltip('重命名');
      await tester.ensureVisible(rename);
      await tester.tap(rename);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '举腿');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(store.exercises, contains('举腿'));
      expect(store.exercises, isNot(contains('卷腹')));
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('新增项目'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '取消的项目');
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(store.exercises, isNot(contains('取消的项目')));
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
      await tester.runAsync(db.close);
    }
  });
}
