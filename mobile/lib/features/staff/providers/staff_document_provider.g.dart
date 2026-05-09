// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_document_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$staffDocumentServiceHash() =>
    r'6f253ae5366fa326171e570cd6e7523f52312ca6';

/// See also [staffDocumentService].
@ProviderFor(staffDocumentService)
final staffDocumentServiceProvider = Provider<StaffDocumentService>.internal(
  staffDocumentService,
  name: r'staffDocumentServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$staffDocumentServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StaffDocumentServiceRef = ProviderRef<StaffDocumentService>;
String _$staffDocumentsHash() => r'e47b6e6cbeaa7f210bf3fa6412f707be6b1b7cb6';

/// See also [staffDocuments].
@ProviderFor(staffDocuments)
final staffDocumentsProvider =
    AutoDisposeFutureProvider<List<DocumentModel>>.internal(
      staffDocuments,
      name: r'staffDocumentsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$staffDocumentsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StaffDocumentsRef = AutoDisposeFutureProviderRef<List<DocumentModel>>;
String _$studentSearchHash() => r'4ba4d3e61903afef07002da8032019b5c8e9c675';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [studentSearch].
@ProviderFor(studentSearch)
const studentSearchProvider = StudentSearchFamily();

/// See also [studentSearch].
class StudentSearchFamily
    extends Family<AsyncValue<List<StudentSummaryModel>>> {
  /// See also [studentSearch].
  const StudentSearchFamily();

  /// See also [studentSearch].
  StudentSearchProvider call(String query) {
    return StudentSearchProvider(query);
  }

  @override
  StudentSearchProvider getProviderOverride(
    covariant StudentSearchProvider provider,
  ) {
    return call(provider.query);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'studentSearchProvider';
}

/// See also [studentSearch].
class StudentSearchProvider
    extends AutoDisposeFutureProvider<List<StudentSummaryModel>> {
  /// See also [studentSearch].
  StudentSearchProvider(String query)
    : this._internal(
        (ref) => studentSearch(ref as StudentSearchRef, query),
        from: studentSearchProvider,
        name: r'studentSearchProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$studentSearchHash,
        dependencies: StudentSearchFamily._dependencies,
        allTransitiveDependencies:
            StudentSearchFamily._allTransitiveDependencies,
        query: query,
      );

  StudentSearchProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.query,
  }) : super.internal();

  final String query;

  @override
  Override overrideWith(
    FutureOr<List<StudentSummaryModel>> Function(StudentSearchRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudentSearchProvider._internal(
        (ref) => create(ref as StudentSearchRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        query: query,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<StudentSummaryModel>> createElement() {
    return _StudentSearchProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentSearchProvider && other.query == query;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin StudentSearchRef
    on AutoDisposeFutureProviderRef<List<StudentSummaryModel>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _StudentSearchProviderElement
    extends AutoDisposeFutureProviderElement<List<StudentSummaryModel>>
    with StudentSearchRef {
  _StudentSearchProviderElement(super.provider);

  @override
  String get query => (origin as StudentSearchProvider).query;
}

String _$staffDocumentFilterHash() =>
    r'bccb3d48dceb92b80757afee98eb62bb83f34f60';

/// See also [StaffDocumentFilter].
@ProviderFor(StaffDocumentFilter)
final staffDocumentFilterProvider =
    AutoDisposeNotifierProvider<StaffDocumentFilter, String?>.internal(
      StaffDocumentFilter.new,
      name: r'staffDocumentFilterProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$staffDocumentFilterHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$StaffDocumentFilter = AutoDisposeNotifier<String?>;
String _$staffDocumentTypeFilterHash() =>
    r'75d88dc161c6a51c93765035459dec49c4e971a4';

/// See also [StaffDocumentTypeFilter].
@ProviderFor(StaffDocumentTypeFilter)
final staffDocumentTypeFilterProvider =
    AutoDisposeNotifierProvider<StaffDocumentTypeFilter, String?>.internal(
      StaffDocumentTypeFilter.new,
      name: r'staffDocumentTypeFilterProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$staffDocumentTypeFilterHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$StaffDocumentTypeFilter = AutoDisposeNotifier<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
