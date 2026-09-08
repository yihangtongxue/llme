import 'package:flutter/material.dart';
import 'package:llme/data/workout_store.dart';
import 'package:llme/features/trends/trends_page.dart';
import 'package:llme/shared/widgets/workout_ui.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.store});
  final WorkoutStore store;

  @override
  Widget build(BuildContext context) => PageContent(
    children: [
      const PageHeading('我的', null),
      Surface(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _ProfileTile(
              title: '训练数据',
              subtitle: '查看本周训练与项目变化',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _DetailScaffold(
                    title: '训练数据',
                    child: TrendsPage(store: store, showHeading: false),
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEAF0F2)),
            _ProfileTile(
              title: '关于应用',
              subtitle: '了解练了么',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AboutPage()),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) => _DetailScaffold(
    title: '关于应用',
    child: PageContent(
      children: [
        Surface(
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  'assets/branding/llme.png',
                  width: 88,
                  height: 88,
                  fit: BoxFit.cover,
                  semanticLabel: '练了么品牌标志',
                ),
              ),
              SizedBox(height: 14),
              Text(
                '练了么',
                style: TextStyle(
                  color: ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 6),
              Text('快速记录每一次训练', style: TextStyle(color: muted)),
              SizedBox(height: 22),
              Divider(height: 1, color: Color(0xFFEAF0F2)),
              SizedBox(height: 16),
              _AboutItem(label: '版本', value: '1.0.0'),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DetailScaffold extends StatelessWidget {
  const _DetailScaffold({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title),
      centerTitle: true,
      backgroundColor: const Color(0xFFF3F7F8),
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    body: ColoredBox(color: const Color(0xFFF3F7F8), child: child),
  );
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: title,
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: muted),
          ],
        ),
      ),
    ),
  );
}

class _AboutItem extends StatelessWidget {
  const _AboutItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(label, style: const TextStyle(color: muted, fontSize: 13)),
      const Spacer(),
      Text(value, style: const TextStyle(color: ink, fontSize: 13)),
    ],
  );
}
