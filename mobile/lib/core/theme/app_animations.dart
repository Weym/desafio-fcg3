import 'dart:math' show min;
import 'package:flutter/material.dart';

/// Centralized animation constants for the Cyber-Academic design system.
/// All durations, curves, and offsets for micro-animations and transitions.
class AppAnimations {
  AppAnimations._(); // prevent instantiation

  // === Entrance Animations ===
  /// Duration for fade+slide entrance (cards, sections)
  static const Duration entranceDuration = Duration(milliseconds: 800);
  /// Default curve for entrance animations
  static const Curve entranceCurve = Curves.easeOutCubic;
  /// Vertical slide offset (pixels) for entrance animation
  static const double entranceSlideOffset = 20.0;
  /// Base stagger delay between consecutive items
  static const Duration staggerDelay = Duration(milliseconds: 150);
  /// Maximum stagger index — delays are capped here to prevent timer storms
  static const int maxStaggerIndex = 5;

  // === Navigation Bar ===
  /// Duration for nav bar selection transition
  static const Duration navTransitionDuration = Duration(milliseconds: 300);
  /// Curve for nav bar glow + scale effect
  static const Curve navTransitionCurve = Curves.easeOutBack;
  /// Icon size when selected in nav bar
  static const double navIconSizeSelected = 28.0;
  /// Icon size when unselected in nav bar
  static const double navIconSizeDefault = 24.0;
  /// Glow spread radius when nav item is selected
  static const double navGlowSpreadSelected = 4.0;
  /// Glow blur radius when nav item is selected
  static const double navGlowBlurSelected = 16.0;

  // === Page Transitions ===
  /// Duration for fade-through transition (tab switches)
  static const Duration fadeThroughDuration = Duration(milliseconds: 300);
  /// Duration for horizontal slide transition (push routes)
  static const Duration slideDuration = Duration(milliseconds: 250);
  /// Curve for page transitions
  static const Curve pageTransitionCurve = Curves.easeInOut;

  // === Stagger Formula ===
  /// Centralized stagger delay calculation.
  /// Returns `Duration(milliseconds: min(index, maxStaggerIndex) * staggerDelay.inMilliseconds)`.
  /// Capped at [maxStaggerIndex] to prevent timer storms on long lists.
  ///
  /// Usage: `delay: AppAnimations.getEntranceDelay(index)`
  static Duration getEntranceDelay(int index) {
    return Duration(
      milliseconds: min(index, maxStaggerIndex) * staggerDelay.inMilliseconds,
    );
  }
}
