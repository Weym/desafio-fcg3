// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_chat_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$staffChatServiceHash() => r'296c7e28391ba7ca997822ea11bd9f82932e0841';

/// See also [staffChatService].
@ProviderFor(staffChatService)
final staffChatServiceProvider = Provider<StaffChatService>.internal(
  staffChatService,
  name: r'staffChatServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$staffChatServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StaffChatServiceRef = ProviderRef<StaffChatService>;
String _$staffChatSessionsHash() => r'8e6e7023cde8a3e89550aca5f8e400c1353a4e12';

/// See also [staffChatSessions].
@ProviderFor(staffChatSessions)
final staffChatSessionsProvider =
    AutoDisposeFutureProvider<List<ChatSessionModel>>.internal(
      staffChatSessions,
      name: r'staffChatSessionsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$staffChatSessionsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StaffChatSessionsRef =
    AutoDisposeFutureProviderRef<List<ChatSessionModel>>;
String _$staffChatMessagesHash() => r'c8b82bfe8cbd5027a91ddd37477c3ff4ff6001e5';

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

/// See also [staffChatMessages].
@ProviderFor(staffChatMessages)
const staffChatMessagesProvider = StaffChatMessagesFamily();

/// See also [staffChatMessages].
class StaffChatMessagesFamily
    extends Family<AsyncValue<List<ChatMessageModel>>> {
  /// See also [staffChatMessages].
  const StaffChatMessagesFamily();

  /// See also [staffChatMessages].
  StaffChatMessagesProvider call(String sessionId) {
    return StaffChatMessagesProvider(sessionId);
  }

  @override
  StaffChatMessagesProvider getProviderOverride(
    covariant StaffChatMessagesProvider provider,
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
  String? get name => r'staffChatMessagesProvider';
}

/// See also [staffChatMessages].
class StaffChatMessagesProvider
    extends AutoDisposeFutureProvider<List<ChatMessageModel>> {
  /// See also [staffChatMessages].
  StaffChatMessagesProvider(String sessionId)
    : this._internal(
        (ref) => staffChatMessages(ref as StaffChatMessagesRef, sessionId),
        from: staffChatMessagesProvider,
        name: r'staffChatMessagesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$staffChatMessagesHash,
        dependencies: StaffChatMessagesFamily._dependencies,
        allTransitiveDependencies:
            StaffChatMessagesFamily._allTransitiveDependencies,
        sessionId: sessionId,
      );

  StaffChatMessagesProvider._internal(
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
    FutureOr<List<ChatMessageModel>> Function(StaffChatMessagesRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StaffChatMessagesProvider._internal(
        (ref) => create(ref as StaffChatMessagesRef),
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
    return _StaffChatMessagesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StaffChatMessagesProvider && other.sessionId == sessionId;
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
mixin StaffChatMessagesRef
    on AutoDisposeFutureProviderRef<List<ChatMessageModel>> {
  /// The parameter `sessionId` of this provider.
  String get sessionId;
}

class _StaffChatMessagesProviderElement
    extends AutoDisposeFutureProviderElement<List<ChatMessageModel>>
    with StaffChatMessagesRef {
  _StaffChatMessagesProviderElement(super.provider);

  @override
  String get sessionId => (origin as StaffChatMessagesProvider).sessionId;
}

String _$staffActionLogsHash() => r'ba5f0dfd655eac61b41b86c0f2e1f6b5924cab0f';

/// See also [staffActionLogs].
@ProviderFor(staffActionLogs)
const staffActionLogsProvider = StaffActionLogsFamily();

/// See also [staffActionLogs].
class StaffActionLogsFamily extends Family<AsyncValue<List<ActionLogModel>>> {
  /// See also [staffActionLogs].
  const StaffActionLogsFamily();

  /// See also [staffActionLogs].
  StaffActionLogsProvider call(String sessionId) {
    return StaffActionLogsProvider(sessionId);
  }

  @override
  StaffActionLogsProvider getProviderOverride(
    covariant StaffActionLogsProvider provider,
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
  String? get name => r'staffActionLogsProvider';
}

/// See also [staffActionLogs].
class StaffActionLogsProvider
    extends AutoDisposeFutureProvider<List<ActionLogModel>> {
  /// See also [staffActionLogs].
  StaffActionLogsProvider(String sessionId)
    : this._internal(
        (ref) => staffActionLogs(ref as StaffActionLogsRef, sessionId),
        from: staffActionLogsProvider,
        name: r'staffActionLogsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$staffActionLogsHash,
        dependencies: StaffActionLogsFamily._dependencies,
        allTransitiveDependencies:
            StaffActionLogsFamily._allTransitiveDependencies,
        sessionId: sessionId,
      );

  StaffActionLogsProvider._internal(
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
    FutureOr<List<ActionLogModel>> Function(StaffActionLogsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StaffActionLogsProvider._internal(
        (ref) => create(ref as StaffActionLogsRef),
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
  AutoDisposeFutureProviderElement<List<ActionLogModel>> createElement() {
    return _StaffActionLogsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StaffActionLogsProvider && other.sessionId == sessionId;
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
mixin StaffActionLogsRef on AutoDisposeFutureProviderRef<List<ActionLogModel>> {
  /// The parameter `sessionId` of this provider.
  String get sessionId;
}

class _StaffActionLogsProviderElement
    extends AutoDisposeFutureProviderElement<List<ActionLogModel>>
    with StaffActionLogsRef {
  _StaffActionLogsProviderElement(super.provider);

  @override
  String get sessionId => (origin as StaffActionLogsProvider).sessionId;
}

String _$staffChatStatisticsHash() =>
    r'b01027420062de39c8475cc112dae47c14a86d49';

/// See also [staffChatStatistics].
@ProviderFor(staffChatStatistics)
final staffChatStatisticsProvider =
    AutoDisposeFutureProvider<Map<String, dynamic>>.internal(
      staffChatStatistics,
      name: r'staffChatStatisticsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$staffChatStatisticsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StaffChatStatisticsRef =
    AutoDisposeFutureProviderRef<Map<String, dynamic>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
