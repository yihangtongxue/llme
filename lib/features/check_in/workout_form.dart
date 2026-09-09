import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:llme/data/exercise_project.dart';
import 'package:llme/data/workout.dart';
import 'package:llme/data/workout_store.dart';
import 'package:llme/shared/widgets/workout_ui.dart';

class WorkoutForm extends StatefulWidget {
  const WorkoutForm({
    super.key,
    required this.store,
    required this.onSaved,
    this.original,
  });
  final WorkoutStore store;
  final Workout? original;
  final void Function(Workout record) onSaved;

  @override
  State<WorkoutForm> createState() => _WorkoutFormState();
}

class _WorkoutFormState extends State<WorkoutForm> {
  String? _exercise;
  String? _energy;
  late String _day;
  List<int> _reps = [12, 12, 12];
  int _minutes = 30;
  bool _timed = false;
  bool _individual = false;
  bool _saving = false;
  Workout? get _previous =>
      _exercise == null ? null : widget.store.latest(_exercise!);
  String? _error;

  @override
  void initState() {
    super.initState();
    final original = widget.original;
    _day = original?.date ?? dayKey(widget.store.today);
    _energy = original != null
        ? original.energy
        : widget.store.energyOn(widget.store.today);
    if (original != null) {
      _exercise = original.exercise;
      _reps = List.of(original.reps);
      _timed = original.isTimed;
      _minutes = original.durationMinutes ?? 30;
      _individual = !_timed && !original.uniform;
    }
  }

  void _select(String exercise) {
    setState(() {
      _exercise = exercise;
      _reps = _previous == null ? [12, 12, 12] : List.of(_previous!.reps);
      _timed = _previous?.isTimed ?? false;
      _minutes = _previous?.durationMinutes ?? 30;
      _individual = !_timed && _previous != null && !_previous!.uniform;
      _error = null;
    });
  }

  void _setCount(int count) => setState(() {
    if (count > _reps.length) {
      _reps = [..._reps, ...List.filled(count - _reps.length, _reps.last)];
    } else {
      _reps = _reps.take(count).toList();
    }
  });

  Future<void> _save() async {
    if (_saving || widget.store.busy) return;
    if (_exercise == null) {
      setState(() => _error = '先选一个训练项目');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final now = widget.store.clock();
      // A form left open overnight belongs to the new day when saved.
      final date = widget.original?.date ?? dayKey(now);
      final energy = date == _day ? _energy : widget.store.energyOn(now);
      final record = Workout(
        id:
            widget.original?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        date: date,
        createdAt: widget.original?.createdAt ?? now,
        exercise: _exercise!,
        reps: _timed ? [_minutes] : _reps,
        durationMinutes: _timed ? _minutes : null,
        energy: energy,
      );
      await widget.store.save(record);
      if (mounted) {
        widget.onSaved(record);
      }
    } catch (_) {
      if (mounted) showFailure(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = dayKey(widget.store.today);
    if (widget.original == null && today != _day) {
      _day = today;
      _energy = widget.store.energyOn(widget.store.today);
    }
    final disabled = _saving || widget.store.busy;
    final String? helperText = _exercise == null
        ? '选择项目后，填写这次完成的数量。'
        : widget.original != null
        ? '记录日期：${widget.original!.date}'
        : _previous != null
        ? '上次：${_previous!.summary} · 已沿用，可修改'
        : null;
    return AbsorbPointer(
      absorbing: disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel(
                  widget.original == null ? '今天精力怎么样？' : '这次训练的精力',
                  hint: '可选',
                ),
                Row(
                  children: [
                    for (final energy in ['低', '中', '高'])
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: energy == '高' ? 0 : 10,
                          ),
                          child: ChoiceChip(
                            label: SizedBox(
                              width: double.infinity,
                              child: Text(energy, textAlign: TextAlign.center),
                            ),
                            selected: _energy == energy,
                            showCheckmark: false,
                            onSelected: (selected) => setState(
                              () => _energy = selected ? energy : null,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionLabel(
                  widget.original == null ? '记录刚刚的训练' : '修改训练记录',
                  hint: _timed ? '按分钟记录' : '按次数记录',
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final exercise in widget.store.projectsByUsage)
                      ChoiceChip(
                        label: _ExerciseLabel(project: exercise),
                        selected: _exercise == exercise.name,
                        showCheckmark: false,
                        onSelected: (_) => _select(exercise.name),
                      ),
                    ),
                  ],
                ),
                if (_exercise != null) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Text(
                        '记录方式',
                        style: TextStyle(fontSize: 12, color: muted),
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text('次数'),
                        selected: !_timed,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _timed = false),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('分钟'),
                        selected: _timed,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _timed = true),
                      ),
                    ],
                  ),
                ],
                if (helperText != null) ...[
                  const SizedBox(height: 18),
                  Text(
                    helperText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: muted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                ] else
                  const SizedBox(height: 18),
                if (_timed)
                  NumberStepper(
                    label: '分钟',
                    value: _minutes,
                    max: 999,
                    enabled: _exercise != null,
                    onChanged: (value) => setState(() => _minutes = value),
                  )
                else ...[
                  NumberStepper(
                    label: '组数',
                    value: _reps.length,
                    max: 30,
                    enabled: _exercise != null,
                    onChanged: _setCount,
                  ),
                  const SizedBox(height: 10),
                ],
                if (!_timed && !_individual)
                  NumberStepper(
                    label: '每组次数',
                    value: _reps.first,
                    max: 999,
                    enabled: _exercise != null,
                    onChanged: (value) => setState(
                      () => _reps = List.filled(_reps.length, value),
                    ),
                  ),
                if (!_timed)
                  Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _exercise == null
                        ? null
                        : () async {
                            if (_individual &&
                                !_reps.every((n) => n == _reps.first)) {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('统一每组次数？'),
                                  content: Text('所有组将改为 ${_reps.first} 次。'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('保留逐组'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('统一次数'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed != true || !mounted) return;
                            }
                            setState(() {
                              _individual = !_individual;
                              if (!_individual) {
                                _reps = List.filled(_reps.length, _reps.first);
                              }
                            });
                          },
                    child: Text(_individual ? '改为每组相同' : '每组不同？'),
                  ),
                ),
                if (!_timed && _individual)
                  for (var i = 0; i < _reps.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: NumberStepper(
                        label: '第 ${i + 1} 组',
                        value: _reps[i],
                        max: 999,
                        onChanged: (value) => setState(() => _reps[i] = value),
                      ),
                    ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                FilledButton(
                  key: const ValueKey('save-workout'),
                  onPressed: disabled ? null : _save,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Text(
                      disabled
                          ? '正在保存…'
                          : widget.original == null
                          ? '保存打卡'
                          : '保存修改',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NumberStepper extends StatelessWidget {
  const NumberStepper({
    super.key,
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
    this.enabled = true,
  });
  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
    decoration: BoxDecoration(
      color: const Color(0xFFF0F5F8),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: ink)),
        ),
        IconButton(
          tooltip: '减少$label',
          onPressed: enabled && value > 1 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_rounded, size: 20),
        ),
        Semantics(
          label: '$label，$value，点击输入',
          button: true,
          child: TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            onPressed: enabled
                ? () async {
                    final result = await showDialog<int>(
                      context: context,
                      builder: (_) =>
                          _NumberDialog(label: label, value: value, max: max),
                    );
                    if (result != null && context.mounted) onChanged(result);
                  }
                : null,
            child: Text(
              '$value',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        IconButton(
          tooltip: '增加$label',
          onPressed: enabled && value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_rounded, size: 20),
        ),
      ],
    ),
  );
}

class _NumberDialog extends StatefulWidget {
  const _NumberDialog({
    required this.label,
    required this.value,
    required this.max,
  });
  final String label;
  final int value;
  final int max;
  @override
  State<_NumberDialog> createState() => _NumberDialogState();
}

class _NumberDialogState extends State<_NumberDialog> {
  late final controller = TextEditingController(text: '${widget.value}')
    ..selection = TextSelection(
      baseOffset: 0,
      extentOffset: '${widget.value}'.length,
    );
  String? error;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void submit() {
    final number = int.tryParse(controller.text);
    if (number == null || number < 1 || number > widget.max) {
      setState(() => error = '请输入 1–${widget.max} 的整数');
    } else {
      Navigator.pop(context, number);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.label),
    content: TextField(
      controller: controller,
      autofocus: true,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(3),
      ],
      decoration: InputDecoration(
        errorText: error,
        helperText: '1–${widget.max}',
      ),
      onSubmitted: (_) => submit(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('取消'),
      ),
      TextButton(onPressed: submit, child: const Text('确定')),
    ],
  );
}

class _ExerciseLabel extends StatelessWidget {
  const _ExerciseLabel({required this.project});
  final ExerciseProject project;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: project.isBuiltIn ? accent : action,
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 6),
      Text(project.name),
    ],
  );
}
