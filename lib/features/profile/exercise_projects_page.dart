import 'package:flutter/material.dart';
import 'package:llme/data/exercise_project.dart';
import 'package:llme/data/workout_store.dart';
import 'package:llme/shared/widgets/workout_ui.dart';

class ExerciseProjectsPage extends StatelessWidget {
  const ExerciseProjectsPage({super.key, required this.store});
  final WorkoutStore store;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('项目维护'),
      centerTitle: true,
      backgroundColor: const Color(0xFFF3F7F8),
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: store.busy ? null : () => _editProject(context, store),
      icon: const Icon(Icons.add_rounded),
      label: const Text('新增项目'),
    ),
    body: ColoredBox(
      color: const Color(0xFFF3F7F8),
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) => ListView(
          padding: EdgeInsets.fromLTRB(
            22,
            24,
            22,
            MediaQuery.paddingOf(context).bottom + 96,
          ),
          children: [
            const Text('项目维护', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: ink)),
            const SizedBox(height: 7),
            const Text('内置项目为蓝色；自定义项目为绿色。同名项目可并存。', style: TextStyle(fontSize: 13, color: muted)),
            const SizedBox(height: 22),
            Surface(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final project in store.exerciseProjects) ...[
                    _ProjectTile(
                      project: project,
                      onRename: () => _editProject(context, store, project: project),
                      onDelete: project.isBuiltIn
                          ? null
                          : () => _confirmDelete(context, store, project),
                    ),
                    if (project != store.exerciseProjects.last)
                      const Divider(height: 1, color: Color(0xFFEAF0F2)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({required this.project, required this.onRename, this.onDelete});
  final ExerciseProject project;
  final VoidCallback onRename;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
    leading: CircleAvatar(
      radius: 6,
      backgroundColor: project.isBuiltIn ? accent : positive,
    ),
    title: Text(project.name, style: const TextStyle(color: ink, fontWeight: FontWeight.w600)),
    subtitle: Text(project.isBuiltIn ? '内置项目' : '自定义项目', style: const TextStyle(color: muted, fontSize: 12)),
    onTap: onRename,
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(tooltip: '重命名', onPressed: onRename, icon: const Icon(Icons.edit_outlined)),
        if (onDelete != null)
          IconButton(
            tooltip: '删除',
            color: Colors.red.shade400,
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
      ],
    ),
  );
}

Future<void> _editProject(
  BuildContext context,
  WorkoutStore store, {
  ExerciseProject? project,
}) async {
  final controller = TextEditingController(text: project?.name);
  String? error;
  final name = await showDialog<String>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(project == null ? '新增训练项目' : '重命名项目'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          decoration: InputDecoration(hintText: '例如：卷腹', errorText: error),
          onSubmitted: (_) {
            final value = controller.text.trim();
            if (value.isEmpty) {
              setState(() => error = '请输入项目名称');
            } else {
              Navigator.pop(dialogContext, value);
            }
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isEmpty) {
                setState(() => error = '请输入项目名称');
              } else {
                Navigator.pop(dialogContext, value);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    ),
  );
  controller.dispose();
  if (name == null || !context.mounted) return;
  try {
    if (project == null) {
      await store.addExercise(name);
    } else {
      await store.renameExercise(project, name);
    }
  } catch (_) {
    if (context.mounted) showFailure(context);
  }
}

Future<void> _confirmDelete(
  BuildContext context,
  WorkoutStore store,
  ExerciseProject project,
) async {
  final remove = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('删除项目？'),
      content: Text('将删除“${project.name}”这个项目。已有训练记录不会被修改。'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('取消')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('删除'),
        ),
      ],
    ),
  );
  if (remove != true || !context.mounted) return;
  try {
    await store.deleteExercise(project);
  } catch (_) {
    if (context.mounted) showFailure(context);
  }
}
