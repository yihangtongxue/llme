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
            const SizedBox(height: 22),
            Material(
              color: const Color(0xFFFEFFFF),
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final project in store.exerciseProjects) ...[
                    _ProjectTile(
                      project: project,
                      onRename: project.isBuiltIn
                          ? null
                          : () => _editProject(context, store, project: project),
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
  const _ProjectTile({required this.project, this.onRename, this.onDelete});
  final ExerciseProject project;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    leading: CircleAvatar(
      radius: 6,
      backgroundColor: project.isBuiltIn ? accent : positive,
    ),
    title: Text(project.name, style: const TextStyle(color: ink, fontWeight: FontWeight.w600)),
    onTap: onRename,
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onRename != null)
          IconButton(
            tooltip: '重命名',
            onPressed: onRename,
            icon: const Icon(Icons.edit_outlined),
          ),
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
  final name = await showDialog<String>(
    context: context,
    builder: (_) => _ProjectNameDialog(project: project),
  );
  if (name == null || !context.mounted) return;
  try {
    if (project == null) {
      await store.addExercise(name);
    } else {
      await store.renameExercise(project, name);
    }
  } on FormatException catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  } catch (error, stackTrace) {
    debugPrint('保存训练项目失败：$error');
    debugPrintStack(stackTrace: stackTrace);
    if (context.mounted) showFailure(context);
  }
}

class _ProjectNameDialog extends StatefulWidget {
  const _ProjectNameDialog({this.project});

  final ExerciseProject? project;

  @override
  State<_ProjectNameDialog> createState() => _ProjectNameDialogState();
}

class _ProjectNameDialogState extends State<_ProjectNameDialog> {
  late final TextEditingController _controller;
  String? _error;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.project?.name);
  }

  @override
  void dispose() {
    // The field stays mounted during the dialog's exit animation.
    _controller.dispose();
    super.dispose();
  }

  void _close([String? value]) {
    if (_closing || ModalRoute.of(context)?.isCurrent != true) return;
    _closing = true;
    Navigator.pop(context, value);
  }

  void _submit() {
    if (_closing) return;
    final value = _controller.text.trim();
    if (value.isEmpty || value.length > 20) {
      setState(() {
        _error = value.isEmpty ? '请输入项目名称' : '项目名称需为 1–20 个字';
      });
      return;
    }
    _close(value);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.project == null ? '新增训练项目' : '重命名项目'),
    content: TextField(
      controller: _controller,
      autofocus: true,
      maxLength: 20,
      decoration: InputDecoration(hintText: '例如：卷腹', errorText: _error),
      onSubmitted: (_) => _submit(),
    ),
    actions: [
      TextButton(onPressed: () => _close(), child: const Text('取消')),
      FilledButton(onPressed: _submit, child: const Text('保存')),
    ],
  );
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
