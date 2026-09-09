import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:llme/data/workout.dart';
import 'package:llme/data/workout_store.dart';
import 'package:llme/main.dart';
import 'package:llme/features/check_in/workout_form.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  testWidgets(
    'save once, inspect calendar/trends, edit and undo without losing state',
    (tester) async {
      tester.view.reset();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      final db = (await tester.runAsync(
        () => databaseFactoryMemory.openDatabase('flow'),
      ))!;
      final store = WorkoutStore(db, clock: () => DateTime(2026, 9, 8, 12));
      await tester.runAsync(store.load);
      await tester.pumpWidget(LlmeApp(store: store));
      await tester.pumpAndSettle();
      expect(find.text('今天精力怎么样？').hitTestable(), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, '俯卧撑').hitTestable());
      await tester.pumpAndSettle();
      final save = find.byKey(const ValueKey('save-workout'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.tap(
        save,
      ); // A rapid repeat tap must not create a second record.
      await tester.pumpAndSettle();
      expect(store.records.length, 1);
      expect(store.records.single.energy, isNull);
      expect(store.records.single.reps, [12, 12, 12]);

      await tester.tap(find.text('撤销').hitTestable());
      await tester.pumpAndSettle();
      expect(store.records, isEmpty);
      await tester.tap(save);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();

      await tester.tap(find.text('日历').hitTestable());
      await tester.pumpAndSettle();
      expect(find.text('本月 1 天有记录').hitTestable(), findsOneWidget);
      await tester.tap(find.text('我的').hitTestable().last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('训练数据').hitTestable());
      await tester.pumpAndSettle();
      expect(find.text('本周训练').hitTestable(), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('打卡').hitTestable());
      await tester.pumpAndSettle();
      expect(find.text('本周训练').hitTestable(), findsNothing);

      final menu = find.byType(PopupMenuButton<String>).hitTestable();
      // Scroll today's record into view.
      final recordMenu = find.byType(PopupMenuButton<String>).last;
      await tester.ensureVisible(recordMenu);
      await tester.pumpAndSettle();
      await tester.tap(menu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('编辑记录').hitTestable());
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('增加组数').hitTestable());
      await tester.pumpAndSettle();
      final editSave = find.text('保存修改');
      await tester.ensureVisible(editSave);
      await tester.tap(editSave);
      await tester.pumpAndSettle();
      expect(store.records.length, 1);
      expect(store.records.single.reps.length, 4);
      await tester.tap(find.text('撤销').hitTestable());
      await tester.pumpAndSettle();
      expect(store.records.single.reps.length, 3);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
      await tester.runAsync(db.close);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );

  testWidgets(
    'small-screen custom project, per-set entry, numeric validation and new day',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      final db = (await tester.runAsync(
        () => databaseFactoryMemory.openDatabase('small'),
      ))!;
      var now = DateTime(2026, 9, 8, 12);
      final store = WorkoutStore(db, clock: () => now);
      await tester.runAsync(store.load);
      await tester.pumpWidget(LlmeApp(store: store));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, '中').hitTestable());
      await tester.tap(find.text('我的').hitTestable().last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('项目维护').hitTestable());
      await tester.pumpAndSettle();
      await tester.tap(find.text('新增项目').hitTestable());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '卷腹');
      await tester.tap(find.text('保存').hitTestable());
      await tester.pumpAndSettle();
      expect(store.exercises, contains('卷腹'));
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('打卡').hitTestable());
      await tester.pumpAndSettle();
      final customChip = find.widgetWithText(ChoiceChip, '卷腹');
      await tester.ensureVisible(customChip);
      await tester.tap(customChip.hitTestable());
      await tester.pumpAndSettle();
      final countInput = find.descendant(
        of: find.byType(WorkoutForm),
        matching: find.widgetWithText(TextButton, '3'),
      );
      await tester.ensureVisible(countInput);
      await tester.tap(countInput);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '0');
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      expect(find.text('请输入 1–30 的整数'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '3');
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('每组不同？'));
      await tester.tap(find.text('每组不同？'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('减少第 2 组'));
      await tester.tap(find.byTooltip('减少第 2 组'));
      await tester.pumpAndSettle();
      final save = find.byKey(const ValueKey('save-workout'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(store.records.single.reps, [12, 11, 12]);
      expect(store.records.single.energy, '中');
      expect(store.exercises, contains('卷腹'));
      now = DateTime(2026, 9, 9, 12);
      store.refreshDay();
      await tester.pumpAndSettle();
      final energy = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, '中'),
      );
      expect(energy.selected, isFalse);
      expect(store.onDate(now), isEmpty);
      expect(store.onDate(shiftDay(now, -1)).length, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
      await tester.runAsync(db.close);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );
}
