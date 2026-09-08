import 'package:flutter/material.dart';
import 'package:llme/app/app_home.dart';
import 'package:llme/data/database.dart';
import 'package:llme/data/workout_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LlmeApp());
}

class LlmeApp extends StatelessWidget {
  const LlmeApp({super.key, this.store});
  final WorkoutStore? store;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'llme',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1877B8)),
      scaffoldBackgroundColor: const Color(0xFFF2F6F8),
      useMaterial3: true,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFEFF4F7),
        selectedColor: const Color(0xFFDCECF5),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        labelStyle: const TextStyle(color: Color(0xFF17324D), fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF17699F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF17324D),
      ),
    ),
    home: store == null ? const _Bootstrap() : AppHome(store: store!),
  );
}

class _Bootstrap extends StatefulWidget {
  const _Bootstrap();
  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  WorkoutStore? _store;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    WorkoutStore? pending;
    try {
      pending = WorkoutStore(await openWorkoutDatabase());
      await pending.load();
      if (!mounted) {
        await pending.database.close();
        pending.dispose();
        return;
      }
      setState(() => _store = pending);
    } catch (_) {
      if (pending != null) {
        await pending.database.close();
        pending.dispose();
      }
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _store?.database.close();
    _store?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_store != null) return AppHome(store: _store!);
    return Scaffold(
      body: Center(
        child: _failed
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('暂时无法读取本机记录'),
                  const SizedBox(height: 12),
                  const Text('已有数据不会被清空，请重试。'),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: _load, child: const Text('重试')),
                ],
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
