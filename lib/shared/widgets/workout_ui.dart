import 'package:flutter/material.dart';

const ink = Color(0xFF17324D);
const muted = Color(0xFF607784);
const accent = Color(0xFF1877B8);
const positive = Color(0xFF168957);
const positiveSoft = Color(0xFFE5F5EC);
const action = Color(0xFFB7E445);

class PageContent extends StatelessWidget {
  const PageContent({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(
      22,
      MediaQuery.paddingOf(context).top + 24,
      22,
      // Keep the last content readable while it scrolls behind the floating
      // glass navigation layer.
      MediaQuery.paddingOf(context).bottom + 104,
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    ),
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading(this.title, this.subtitle, {super.key, this.trailing});
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  color: ink,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 7),
                Text(
                  subtitle!,
                  style: const TextStyle(fontSize: 13, color: muted),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

class Surface extends StatelessWidget {
  const Surface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: const Color(0xFFFEFFFF),
      borderRadius: BorderRadius.circular(18),
    ),
    child: child,
  );
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.title, {super.key, this.hint});
  final String title;
  final String? hint;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            height: 1.2,
            fontWeight: FontWeight.w600,
            color: ink,
          ),
        ),
        if (hint != null)
          Text(hint!, style: const TextStyle(fontSize: 12, color: muted)),
      ],
    ),
  );
}

class EmptyNote extends StatelessWidget {
  const EmptyNote(this.text, {super.key, this.icon = Icons.spa_outlined});
  final String text;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 22),
    child: Column(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 28, color: muted.withValues(alpha: 0.65)),
          const SizedBox(height: 10),
        ],
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: muted, height: 1.6),
        ),
      ],
    ),
  );
}

void showFailure(BuildContext context) {
  ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('未能保存，请重试。原有记录未更改。')));
}
