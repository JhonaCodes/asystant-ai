import 'package:flutter/material.dart';

/// Aula-style activity pulse: only the icon moves, keeping its label readable.
/// Reduced motion leaves the icon fully visible and stops the ticker.
class ChatActivityPulse extends StatefulWidget {
  const ChatActivityPulse({
    super.key,
    required this.child,
    required this.active,
  });

  final Widget child;

  final bool active;

  static const Duration cycle = Duration(milliseconds: 1200);

  static const double minimumOpacity = .15;

  @override
  State<ChatActivityPulse> createState() => _ChatActivityPulseState();
}

class _ChatActivityPulseState extends State<ChatActivityPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: ChatActivityPulse.cycle,
  );

  late final Animation<double> _opacity = Tween<double>(
    begin: 1,
    end: ChatActivityPulse.minimumOpacity,
  ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateMotion();
  }

  @override
  void didUpdateWidget(covariant ChatActivityPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateMotion();
  }

  void _updateMotion() {
    if (widget.active && !MediaQuery.disableAnimationsOf(context)) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _opacity, child: widget.child);
}
