import 'dart:async';

import 'package:flutter/material.dart';
import 'package:llme/data/workout_store.dart';
import 'package:llme/features/calendar/calendar_page.dart';
import 'package:llme/features/check_in/check_in_page.dart';
import 'package:llme/features/profile/profile_page.dart';
import 'package:llme/services/android_update_service.dart';
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
  Object? _pendingUpdateApk;
  AndroidUpdateInfo? _pendingUpdate;
  bool _resumingUpdateInstall = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dayTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => widget.store.refreshDay(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.store.refreshDay();
      unawaited(_resumePendingUpdateInstall());
    }
  }

  @override
  void dispose() {
    _dayTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkForUpdate({bool showNoUpdateFeedback = false}) async {
    final update = await AndroidUpdateService.checkForUpdate();
    if (!mounted) return;
    if (update == null) {
      if (showNoUpdateFeedback) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('当前没有可用更新。')),
        );
      }
      return;
    }
    final shouldDownload = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Text('发现新版本 ${update.versionName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('本次更新内容：'),
              const SizedBox(height: 10),
              for (final note in update.notes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• $note'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('稍后再说'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('立即更新'),
          ),
        ],
      ),
    );
    if (shouldDownload == true && mounted) await _downloadUpdate(update);
  }

  Future<void> _downloadUpdate(AndroidUpdateInfo update) async {
    final progress = ValueNotifier<double?>(null);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('正在下载更新'),
          content: ValueListenableBuilder<double?>(
            valueListenable: progress,
            builder: (_, value, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: value),
                const SizedBox(height: 14),
                Text(value == null ? '正在准备下载…' : '已下载 ${(value * 100).round()}%'),
              ],
            ),
          ),
        ),
      ),
    );
    try {
      final apk = await AndroidUpdateService.download(
        update,
        onProgress: (value) => progress.value = value.clamp(0, 1).toDouble(),
      );
      final result = await AndroidUpdateService.verifyAndInstall(apk, update);
      if (result == AndroidUpdateInstallResult.permissionRequired) {
        _pendingUpdateApk = apk;
        _pendingUpdate = update;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('授权后返回应用，将自动继续安装。')),
          );
        }
      } else {
        _clearPendingUpdateInstall();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('更新失败，请检查网络后重试。')),
        );
      }
    } finally {
      progress.dispose();
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _resumePendingUpdateInstall() async {
    final apk = _pendingUpdateApk;
    final update = _pendingUpdate;
    if (apk == null || update == null || _resumingUpdateInstall) return;
    if (!await AndroidUpdateService.canInstallPackages()) return;
    _resumingUpdateInstall = true;
    try {
      final result = await AndroidUpdateService.verifyAndInstall(apk, update);
      if (result == AndroidUpdateInstallResult.installerOpened) {
        _clearPendingUpdateInstall();
      }
    } catch (_) {
      _clearPendingUpdateInstall();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('未能继续安装更新，请重新检查更新。')),
        );
      }
    } finally {
      _resumingUpdateInstall = false;
    }
  }

  void _clearPendingUpdateInstall() {
    _pendingUpdateApk = null;
    _pendingUpdate = null;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) {
      final pages = [
        CalendarPage(store: widget.store),
        CheckInPage(store: widget.store),
        ProfilePage(
          store: widget.store,
          onCheckUpdate: () => _checkForUpdate(showNoUpdateFeedback: true),
        ),
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
