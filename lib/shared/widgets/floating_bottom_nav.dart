import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FloatingBottomNav extends StatelessWidget {
  const FloatingBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  }) : assert(currentIndex >= 0 && currentIndex < 3);

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = <({String label, IconData icon})>[
    (label: '日历', icon: CupertinoIcons.calendar),
    (label: '打卡', icon: CupertinoIcons.check_mark_circled),
    (label: '我的', icon: CupertinoIcons.person_crop_circle),
  ];

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 320);
    final textHeight = MediaQuery.textScalerOf(context).scale(12) * 1.2;
    final barHeight = math.max(72.0, 25 + 4 + textHeight + 24);
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final panelRadius = BorderRadius.circular(999);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Align(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Builder(
            builder: (context) {
              final panelContent = DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: panelRadius,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: isDark ? 0.24 : 0.48),
                      scheme.surface.withValues(alpha: isDark ? 0.12 : 0.24),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: isDark ? 0.28 : 0.56,
                    ),
                    width: 0.8,
                  ),
                ),
                child: SizedBox(
                  height: barHeight,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final slotWidth = (constraints.maxWidth - 12) / 3;
                      return Stack(
                        children: [
                          // A shared translucent glass control keeps the
                          // selected state fluid instead of painting a solid
                          // blue tab over the whole slot.
                          AnimatedPositioned(
                            duration: duration,
                            curve: Curves.easeInOutCubic,
                            left: 6 + slotWidth * currentIndex,
                            top: 6,
                            bottom: 6,
                            width: slotWidth,
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  color: scheme.primary.withValues(
                                    alpha: isDark ? 0.20 : 0.12,
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(
                                      alpha: isDark ? 0.24 : 0.42,
                                    ),
                                    width: 0.8,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: scheme.primary.withValues(
                                        alpha: isDark ? 0.16 : 0.08,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Row(
                                children: List.generate(_items.length, (
                                  index,
                                ) {
                                  return Expanded(
                                    child: _NavigationItem(
                                      label: _items[index].label,
                                      icon: _items[index].icon,
                                      selected: currentIndex == index,
                                      duration: duration,
                                      onTap: () => onTap(index),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );

              final panel = DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: panelRadius,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.28 : 0.14,
                      ),
                      blurRadius: 24,
                      spreadRadius: -4,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(
                        alpha: isDark ? 0.08 : 0.20,
                      ),
                      blurRadius: 1,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: panelRadius,
                  child: kIsWeb
                      ? panelContent
                      : BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          blendMode: BlendMode.srcOver,
                          child: panelContent,
                        ),
                ),
              );

              return panel;
            },
          ),
        ),
      ),
    );
  }
}

// Fixed icons and a single colour tween avoid the old cross-fade ghosting.
// Keyboard focus has a thin outline; touch never paints a press overlay.
class _NavigationItem extends StatefulWidget {
  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.duration,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Duration duration;
  final VoidCallback onTap;

  @override
  State<_NavigationItem> createState() => _NavigationItemState();
}

class _NavigationItemState extends State<_NavigationItem> {
  bool _showFocus = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      onTap: widget.onTap,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowFocusHighlight: (value) => setState(() => _showFocus = value),
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTap: widget.onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: _showFocus
                  ? Border.all(color: scheme.primary, width: 1.5)
                  : null,
            ),
            child: ExcludeSemantics(
              child: TweenAnimationBuilder<Color?>(
                tween: ColorTween(
                  end: widget.selected
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                ),
                duration: widget.duration,
                curve: Curves.easeInOutCubic,
                builder: (context, color, child) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.icon, size: 25, color: color),
                      const SizedBox(height: 4),
                      Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
