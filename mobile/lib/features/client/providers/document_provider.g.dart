// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$documentServiceHash() => r'9c55e370cf4c9e8a9d8330618bd91014d444528d';

/// See also [documentService].
@ProviderFor(documentService)
final documentServiceProvider = Provider<DocumentService>.internal(
  documentService,
  name: r'documentServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$documentServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DocumentServiceRef = ProviderRef<DocumentService>;
String _$documentsHash() => r'8b36509f6a95b60ececd120e6e45e2939daa8934';

/// See also [documents].
@ProviderFor(documents)
final documentsProvider =
    AutoDisposeFutureProvider<List<DocumentModel>>.internal(
      documents,
      name: r'documentsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$documentsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DocumentsRef = AutoDisposeFutureProviderRef<List<DocumentModel>>;
String _$documentFilterHash() => r'b0987b05c69e91669101356517049214b593da70';

/// See also [DocumentFilter].
@ProviderFor(DocumentFilter)
final documentFilterProvider =
    AutoDisposeNotifierProvider<DocumentFilter, String?>.internal(
      DocumentFilter.new,
      name: r'documentFilterProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$documentFilterHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$DocumentFilter = AutoDisposeNotifier<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
