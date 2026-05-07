import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/staff/screens/staff_documents_screen.dart';
import 'package:frontend/features/client/models/document_model.dart';
import 'package:frontend/features/staff/providers/staff_document_provider.dart';

void main() {
  group('StaffDocumentsScreen - filter chips and document cards (UI-F04)', () {
    testWidgets('renders filter chips: Todos, Pendentes, Prontos',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockDocuments = [
        DocumentModel(
          id: 'doc-1',
          type: 'transcript',
          status: 'requested',
          requestedAt: DateTime(2026, 5, 1),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            staffDocumentsProvider.overrideWith((ref) async => mockDocuments),
          ],
          child: const MaterialApp(
            home: StaffDocumentsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Filter labels
      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('Pendentes'), findsOneWidget);
      expect(find.text('Prontos'), findsOneWidget);
    });

    testWidgets('renders document cards with type label and status',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockDocuments = [
        DocumentModel(
          id: 'doc-1',
          type: 'transcript',
          status: 'requested',
          requestedAt: DateTime(2026, 5, 1),
        ),
        DocumentModel(
          id: 'doc-2',
          type: 'enrollment_proof',
          status: 'ready',
          requestedAt: DateTime(2026, 5, 2),
          fileUrl: '/uploads/doc.pdf',
        ),
        DocumentModel(
          id: 'doc-3',
          type: 'declaration',
          status: 'processing',
          requestedAt: DateTime(2026, 5, 3),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            staffDocumentsProvider.overrideWith((ref) async => mockDocuments),
          ],
          child: const MaterialApp(
            home: StaffDocumentsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Document type labels
      expect(find.text('Histórico Escolar'), findsOneWidget);
      expect(find.text('Comprovante de Matrícula'), findsOneWidget);
      expect(find.text('Declaração'), findsOneWidget);

      // Status labels
      expect(find.text('Solicitado'), findsOneWidget);
      expect(find.text('Pronto'), findsOneWidget);
      expect(find.text('Processando'), findsOneWidget);
    });

    testWidgets('shows FAB for sending documents', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            staffDocumentsProvider
                .overrideWith((ref) async => <DocumentModel>[]),
          ],
          child: const MaterialApp(
            home: StaffDocumentsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('shows empty state when no documents', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            staffDocumentsProvider
                .overrideWith((ref) async => <DocumentModel>[]),
          ],
          child: const MaterialApp(
            home: StaffDocumentsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Nenhum documento'), findsOneWidget);
    });

    testWidgets('shows AppBar with title Documentos', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            staffDocumentsProvider
                .overrideWith((ref) async => <DocumentModel>[]),
          ],
          child: const MaterialApp(
            home: StaffDocumentsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Documentos'), findsOneWidget);
    });
  });
}
