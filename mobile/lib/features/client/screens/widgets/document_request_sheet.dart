import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows the document request bottom sheet. Called from DocumentsScreen FAB.
void showDocumentRequestSheet(BuildContext context, WidgetRef ref) {
  // Placeholder — full implementation in Task 2
  showModalBottomSheet(
    context: context,
    builder: (context) => const SizedBox.shrink(),
  );
}
