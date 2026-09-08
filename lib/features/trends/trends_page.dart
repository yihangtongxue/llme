import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:llme/data/workout.dart';
import 'package:llme/data/workout_store.dart';
import 'package:llme/shared/widgets/workout_ui.dart';

class TrendsPage extends StatefulWidget {
  const TrendsPage({super.key, required this.store, this.showHeading = true});
  final WorkoutStore store;
  final bool showHeading;
  @override
  State<TrendsPage> createState() => _TrendsPageState();
}

class _TrendsPageState extends State<TrendsPage> {
  String? _exercise;

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final start = weekStart(store.today);
    final weeks = List.generate(4, (i) => shiftDay(start, (i - 3) * 7));
    final counts = weeks
        .map((w) => store.daysBetween(w, shiftDay(w, 7)))
        .toList();
    final trainedExercises = store.exercises
        .where((name) => store.latest(name) != null)
        .toList();
    if (!trainedExercises.contains(_exercise)) {
      _exercise = trainedExercises.firstOrNull;
    }
    final totals = weeks
        .map(
          (w) => store
              .between(w, shiftDay(w, 7), exercise: _exercise)
              .fold(0, (sum, r) => sum + r.total),
        )
        .toList();

    return PageContent(
      children: [
        if (widget.showHeading) const PageHeading('训练数据', null),
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('本周训练'),
              RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style
                      .copyWith(color: ink),
                  children: [
                    TextSpan(
                      text: '${counts.last}',
                      style: const TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    const TextSpan(
                      text: '  天',
                      style: TextStyle(fontSize: 16, color: muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: store.onDate(shiftDay(start, i)).isNotEmpty
                                  ? const Color(0xFFD8EEF9)
                                  : const Color(0xFFF0F4F6),
                            ),
                            child: store.onDate(shiftDay(start, i)).isNotEmpty
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 17,
                                    color: positive,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 7),
                          Text(
                            ['一', '二', '三', '四', '五', '六', '日'][i],
                            style: const TextStyle(fontSize: 11, color: muted),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('最近四周', hint: '训练天数'),
              _Bars(values: counts, weeks: weeks, maximum: 7, unit: '天'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionLabel('项目变化', hint: '总次数'),
              if (trainedExercises.isEmpty)
                const EmptyNote(
                  '暂无项目记录',
                  icon: null,
                )
              else ...[
                DropdownButton<String>(
                  value: _exercise,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  items: trainedExercises
                      .map(
                        (name) =>
                            DropdownMenuItem(value: name, child: Text(name)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _exercise = value),
                ),
                const SizedBox(height: 12),
                _Bars(
                  values: totals,
                  weeks: weeks,
                  maximum: math.max(1, totals.reduce(math.max)),
                  unit: '次',
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Bars extends StatelessWidget {
  const _Bars({
    required this.values,
    required this.weeks,
    required this.maximum,
    required this.unit,
  });
  final List<int> values;
  final List<DateTime> weeks;
  final int maximum;
  final String unit;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      for (var i = 0; i < values.length; i++)
        Expanded(
          child: Semantics(
            label: '${weeks[i].month}月${weeks[i].day}日起的一周，${values[i]}$unit',
            child: Column(
              children: [
                Text(
                  '${values[i]}',
                  style: TextStyle(
                    color: i == 3 ? accent : muted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 92,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: AnimatedContainer(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 300),
                      height: values[i] == 0 ? 3 : 92 * values[i] / maximum,
                      width: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: i == 3
                              ? [const Color(0xFF2B9B75), action]
                              : [
                                  const Color(0xFFB7CFDD),
                                  const Color(0xFFDCE7ED),
                                ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  i == 3 ? '本周' : '${weeks[i].month}/${weeks[i].day}',
                  style: const TextStyle(color: muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}
