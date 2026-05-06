import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AppSkeletonCard extends StatelessWidget {
  final double height;
  final double? width;
  final EdgeInsets margin;

  const AppSkeletonCard({
    super.key,
    this.height = 120,
    this.width,
    this.margin = const EdgeInsets.only(bottom: 12),
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHighest,
      highlightColor: colorScheme.surface,
      child: Container(
        height: height,
        width: width,
        margin: margin,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
