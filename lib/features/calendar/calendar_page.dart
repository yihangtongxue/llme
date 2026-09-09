import 'package:flutter/material.dart';
import 'package:llme/data/workout.dart';
import 'package:llme/data/workout_store.dart';
import 'package:llme/shared/widgets/record_list.dart';
import 'package:llme/shared/widgets/workout_ui.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key, required this.store});
  final WorkoutStore store;
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _selected = widget.store.today;
  late DateTime _month = DateTime(_selected.year, _selected.month);

  void _move(int offset) => setState(() {
    _month = DateTime(_month.year, _month.month + offset);
    final today = widget.store.today;
    _selected = _month.year == today.year && _month.month == today.month
        ? today
        : _month;
  });

  @override
  Widget build(BuildContext context) {
    final today = widget.store.today;
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final startOffset = _month.weekday - 1;
    final rows = ((startOffset + days) / 7).ceil();
    final marks = widget.store.records.map((r) => r.date).toSet();
    final count = widget.store.daysBetween(
      _month,
      DateTime(_month.year, _month.month + 1),
    );
    final currentMonth = DateTime(today.year, today.month);
    return PageContent(
      children: [
        const PageHeading('日历', null),
        Surface(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            children: [
              Row(
                children: [
                  _monthButton(
                    tooltip: '上个月',
                    icon: Icons.chevron_left_rounded,
                    onPressed: () => _move(-1),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${_month.year}',
                          style: const TextStyle(
                            color: muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_month.month} 月',
                          style: const TextStyle(
                            color: ink,
                            fontSize: 20,
                            height: 1.1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _monthButton(
                    tooltip: '下个月',
                    icon: Icons.chevron_right_rounded,
                    onPressed: _month.isBefore(currentMonth)
                        ? () => _move(1)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F9FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    for (final label in ['一', '二', '三', '四', '五', '六', '日'])
                      Expanded(
                        child: Center(
                          child: Text(
                            label,
                            style: TextStyle(
                              color: label == '日' || label == '六'
                                  ? accent.withValues(alpha: 0.72)
                                  : muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              for (var row = 0; row < rows; row++)
                Row(
                  children: [
                    for (var col = 0; col < 7; col++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: _cell(
                            row * 7 + col - startOffset + 1,
                            days,
                            today,
                            marks,
                          ),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFEAF0F2)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '本月已记录 $count 天',
                      style: const TextStyle(
                        color: muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: accent,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(0, 34),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => setState(() {
                      _selected = today;
                      _month = currentMonth;
                    }),
                    child: const Text('回到今天'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        SectionLabel(
          '${_selected.month} 月 ${_selected.day} 日',
          hint: dayKey(_selected) == dayKey(today) ? '今天' : null,
        ),
        RecordList(
          records: widget.store.onDate(_selected),
          store: widget.store,
          emptyText: '这一天没有记录\n休息也是生活的一部分。',
          emptyIcon: null,
        ),
      ],
    );
  }

  Widget _monthButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
  }) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    style: IconButton.styleFrom(
      backgroundColor: const Color(0xFFF3F8FA),
      foregroundColor: ink,
      disabledForegroundColor: muted.withValues(alpha: 0.35),
      fixedSize: const Size(38, 38),
      padding: EdgeInsets.zero,
    ),
    icon: Icon(icon, size: 20),
  );

  Widget _cell(int number, int days, DateTime today, Set<String> marks) {
    if (number < 1 || number > days) {
      return const AspectRatio(aspectRatio: 1, child: SizedBox());
    }
    final date = DateTime(_month.year, _month.month, number);
    final selected = dayKey(date) == dayKey(_selected);
    final isToday = dayKey(date) == dayKey(today);
    final marked = marks.contains(dayKey(date));
    final future = date.isAfter(today);
    return Semantics(
      label: '${date.year}年${date.month}月$number日，${marked ? '有记录' : '无记录'}',
      selected: selected,
      child: AspectRatio(
        aspectRatio: 1,
        child: TextButton(
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: selected && !marked
                  ? const BorderSide(color: accent, width: 1.5)
                  : BorderSide.none,
            ),
            backgroundColor: marked
                ? accent
                : isToday
                ? const Color(0xFFEAF5FA)
                : null,
            foregroundColor: marked ? Colors.white : ink,
          ),
          onPressed: future ? null : () => setState(() => _selected = date),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: 14,
                fontWeight: marked || selected || isToday
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
