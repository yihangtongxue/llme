import 'package:flutter/material.dart';
import 'package:llme/data/workout_store.dart';
import 'package:llme/shared/widgets/record_list.dart';
import 'package:llme/shared/widgets/workout_ui.dart';

import 'workout_form.dart';

class CheckInPage extends StatelessWidget {
  const CheckInPage({super.key, required this.store});
  final WorkoutStore store;

  @override
  Widget build(BuildContext context) {
    final now = store.today;
    return PageContent(
      children: [
        PageHeading(
          '打卡',
          null,
          trailing: Text(
            '${now.month} 月 ${now.day} 日',
            style: const TextStyle(
              color: ink,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        WorkoutForm(
          store: store,
          onSaved: (record) => showSaved(context, record),
        ),
      ],
    );
  }
}
