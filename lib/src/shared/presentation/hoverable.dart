import 'package:flutter/material.dart';

class Hoverable extends StatefulWidget {
  const Hoverable({
    required this.child,
    this.onTap,
    this.builder,
    this.scaleFactor = 1.015,
    this.duration = const Duration(milliseconds: 200),
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Widget Function(BuildContext context, bool isHovered, Widget child)? builder;
  final double scaleFactor;
  final Duration duration;

  @override
  State<Hoverable> createState() => _HoverableState();
}

class _HoverableState extends State<Hoverable> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isClickable = widget.onTap != null;
    final theme = Theme.of(context);
    
    Widget current = widget.builder != null
        ? widget.builder!(context, _isHovered, widget.child)
        : widget.child;

    return MouseRegion(
      cursor: isClickable && _isHovered ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? widget.scaleFactor : 1.0,
          duration: widget.duration,
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: widget.duration,
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [],
            ),
            child: current,
          ),
        ),
      ),
    );
  }
}
