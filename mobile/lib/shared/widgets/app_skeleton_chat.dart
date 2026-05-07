import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AppSkeletonChat extends StatelessWidget {
  final int itemCount;

  const AppSkeletonChat({
    super.key,
    this.itemCount = 7,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHighest,
      highlightColor: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          children: List.generate(itemCount, (i) {
            // Alternate: even indices = left (bot), odd = right (user)
            final isUser = i.isOdd;
            final widthFraction = isUser ? 0.5 : 0.7;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Align(
                alignment:
                    isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: widthFraction,
                  child: Container(
                    height: 40 + (i % 3) * 8.0, // Vary heights: 40, 48, 56
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
