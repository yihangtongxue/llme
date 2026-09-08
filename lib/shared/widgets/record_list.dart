import 'package:flutter/material.dart';
import 'package:llme/data/workout.dart';
import 'package:llme/data/workout_store.dart';
import 'package:llme/features/check_in/workout_form.dart';

import 'workout_ui.dart';

void showSaved(
  BuildContext context,
  Workout record, {
  Workout? original,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        '${original == null ? '已记录' : '已修改'}：${record.exercise} ${record.summary}',
      ),
      // Keep the save confirmation transient. A SnackBar with an action can
      // remain visible indefinitely under accessibility navigation settings.
      duration: const Duration(seconds: 2),
    ),
  );
}

class RecordList extends StatelessWidget {
  const RecordList({
    super.key,
    required this.records,
    required this.store,
    this.emptyText = '这一天还没有记录',
    this.emptyIcon = Icons.spa_outlined,
  });
  final List<Workout> records;
  final WorkoutStore store;
  final String emptyText;
  final IconData? emptyIcon;

  Future<void> _edit(BuildContext context, Workout record) async {
    final result = await showModalBottomSheet<Workout>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFFF2F6F8),
      builder: (context) => ListenableBuilder(
        listenable: store,
        builder: (context, _) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            MediaQuery.viewInsetsOf(context).bottom +
                MediaQuery.paddingOf(context).bottom +
                24,
          ),
          child: WorkoutForm(
            store: store,
            original: record,
            onSaved: (updated) => Navigator.pop(context, updated),
          ),
        ),
      ),
    );
    if (result != null && context.mounted) {
      showSaved(context, result, original: record);
    }
  }

  Future<void> _delete(BuildContext context, Workout record) async {
    try {
      await store.remove(record.id);
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('已删除：${record.exercise}'),
          action: SnackBarAction(
            label: '撤销',
            onPressed: () async {
              try {
                await store.save(record);
              } catch (_) {
                if (context.mounted) showFailure(context);
              }
            },
          ),
        ),
      );
    } catch (_) {
      if (context.mounted) showFailure(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Surface(child: EmptyNote(emptyText, icon: emptyIcon));
    }
    return Column(
      children: [
        for (final record in records)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Surface(
              padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        foregroundColor: ink,
                      ),
                      onPressed: store.busy
                          ? null
                          : () => _edit(context, record),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.exercise,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            record.summary,
                            style: const TextStyle(fontSize: 12, color: muted),
                          ),
                          if (record.energy != null)
                            Text(
                              '精力 · ${record.energy}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: muted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: '记录操作',
                    enabled: !store.busy,
                    onSelected: (value) {
                      if (value == 'edit') {
                        _edit(context, record);
                      } else {
                        _delete(context, record);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('编辑记录')),
                      PopupMenuItem(value: 'delete', child: Text('删除记录')),
                    ],
                    icon: const Icon(Icons.more_horiz_rounded, color: muted),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
