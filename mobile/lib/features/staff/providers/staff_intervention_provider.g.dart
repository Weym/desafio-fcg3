// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_intervention_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$staffInterventionServiceHash() =>
    r'8b562579e8dd367085ea9e11cafcbad0613616cb';

/// See also [staffInterventionService].
@ProviderFor(staffInterventionService)
final staffInterventionServiceProvider =
    Provider<StaffInterventionService>.internal(
      staffInterventionService,
      name: r'staffInterventionServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$staffInterventionServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StaffInterventionServiceRef = ProviderRef<StaffInterventionService>;
String _$interventionSessionsHash() =>
    r'a192147fc6f7148dfaef0f010f000cee533395c7';

/// See also [interventionSessions].
@ProviderFor(interventionSessions)
final interventionSessionsProvider =
    AutoDisposeFutureProvider<List<InterventionSessionModel>>.internal(
      interventionSessions,
      name: r'interventionSessionsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$interventionSessionsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef InterventionSessionsRef =
    AutoDisposeFutureProviderRef<List<InterventionSessionModel>>;
String _$interventionMessagesHash() =>
    r'16370bcf7f430fcae353b000de293c253f6a91fd';

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

/// See also [interventionMessages].
@ProviderFor(interventionMessages)
const interventionMessagesProvider = InterventionMessagesFamily();

/// See also [interventionMessages].
class InterventionMessagesFamily
    extends Family<AsyncValue<List<ChatMessageModel>>> {
  /// See also [interventionMessages].
  const InterventionMessagesFamily();

  /// See also [interventionMessages].
  InterventionMessagesProvider call(String sessionId) {
    return InterventionMessagesProvider(sessionId);
  }

  @override
  InterventionMessagesProvider getProviderOverride(
    covariant InterventionMessagesProvider provider,
  ) {
    return call(provider.sessionId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'interventionMessagesProvider';
}

/// See also [interventionMessages].
class InterventionMessagesProvider
    extends AutoDisposeFutureProvider<List<ChatMessageModel>> {
  /// See also [interventionMessages].
  InterventionMessagesProvider(String sessionId)
    : this._internal(
        (ref) =>
            interventionMessages(ref as InterventionMessagesRef, sessionId),
        from: interventionMessagesProvider,
        name: r'interventionMessagesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$interventionMessagesHash,
        dependencies: InterventionMessagesFamily._dependencies,
        allTransitiveDependencies:
            InterventionMessagesFamily._allTransitiveDependencies,
        sessionId: sessionId,
      );

  InterventionMessagesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.sessionId,
  }) : super.internal();

  final String sessionId;

  @override
  Override overrideWith(
    FutureOr<List<ChatMessageModel>> Function(InterventionMessagesRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: InterventionMessagesProvider._internal(
        (ref) => create(ref as InterventionMessagesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        sessionId: sessionId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<ChatMessageModel>> createElement() {
    return _InterventionMessagesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is InterventionMessagesProvider &&
        other.sessionId == sessionId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, sessionId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin InterventionMessagesRef
    on AutoDisposeFutureProviderRef<List<ChatMessageModel>> {
  /// The parameter `sessionId` of this provider.
  String get sessionId;
}

class _InterventionMessagesProviderElement
    extends AutoDisposeFutureProviderElement<List<ChatMessageModel>>
    with InterventionMessagesRef {
  _InterventionMessagesProviderElement(super.provider);

  @override
  String get sessionId => (origin as InterventionMessagesProvider).sessionId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
