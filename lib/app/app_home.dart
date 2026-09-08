import 'dart:async';

import 'package:flutter/material.dart';
import 'package:llme/data/workout_store.dart';
import 'package:llme/features/calendar/calendar_page.dart';
import 'package:llme/features/check_in/check_in_page.dart';
import 'package:llme/features/profile/profile_page.dart';
import 'package:llme/shared/widgets/floating_bottom_nav.dart';

class AppHome extends StatefulWidget {
  const AppHome({super.key, required this.store});
  final WorkoutStore store;

  @override
  State<AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends State<AppHome> with WidgetsBindingObserver {
  int _currentIndex = 1;
  Timer? _dayTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dayTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => widget.store.refreshDay(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) widget.store.refreshDay();
  }

  @override
  void dispose() {
    _dayTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) {
      final pages = [
        CalendarPage(store: widget.store),
        CheckInPage(store: widget.store),
        ProfilePage(store: widget.store),
      ];
      return Scaffold(
        extendBody: true,
        body: ColoredBox(
          color: Color(0xFFF3F7F8),
          child: Stack(
            children: List.generate(pages.length, (index) {
              final active = _currentIndex == index;
              return Positioned.fill(
                child: IgnorePointer(
                  ignoring: !active,
                  child: ExcludeFocus(
                    excluding: !active,
                    child: ExcludeSemantics(
                      excluding: !active,
                      child: AnimatedOpacity(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        opacity: active ? 1 : 0,
                        child: TickerMode(enabled: active, child: pages[index]),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        bottomNavigationBar: FloatingBottomNav(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index != _currentIndex) {
              FocusScope.of(context).unfocus();
              setState(() => _currentIndex = index);
            }
          },
        ),
      );
    },
  );
}
