import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_animations.dart';

/// Reusable entrance animation: fade + slide-up with configurable delay.
/// Respects reduced-motion accessibility setting.
///
/// Lifecycle safety: Uses [Timer] instead of [Future.delayed] so the
/// pending callback can be canceled in [dispose], preventing
/// "setState() called after dispose()" errors.
///
/// Animates exactly once on mount. Parent rebuilds do NOT retrigger
/// the animation — the [_visible] flag persists in State.
class AnimatedEntrance extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration? duration;
  final Curve? curve;
  final double? slideOffset;

  const AnimatedEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration,
    this.curve,
    this.slideOffset,
  });

  @override
  State<AnimatedEntrance> createState() => _AnimatedEntranceState();
}

class _AnimatedEntranceState extends State<AnimatedEntrance> {
  bool _visible = false;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _visible = true;
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (mounted) setState(() => _visible = true);
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Respect reduced-motion accessibility setting
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      return widget.child;
    }

    final duration = widget.duration ?? AppAnimations.entranceDuration;
    final curve = widget.curve ?? AppAnimations.entranceCurve;
    final offset = widget.slideOffset ?? AppAnimations.entranceSlideOffset;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: _visible ? 1.0 : 0.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, offset * (1 - value)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
