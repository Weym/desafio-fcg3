// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chatServiceHash() => r'fbba6aa108f75ad24a04209079059a4eecc93388';

/// See also [chatService].
@ProviderFor(chatService)
final chatServiceProvider = Provider<ChatService>.internal(
  chatService,
  name: r'chatServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$chatServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ChatServiceRef = ProviderRef<ChatService>;
String _$chatSessionsHash() => r'6dcac50f63c4a1e31356712c3552210ef104fc46';

/// See also [chatSessions].
@ProviderFor(chatSessions)
final chatSessionsProvider =
    AutoDisposeFutureProvider<List<ChatSessionModel>>.internal(
      chatSessions,
      name: r'chatSessionsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$chatSessionsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ChatSessionsRef = AutoDisposeFutureProviderRef<List<ChatSessionModel>>;
String _$chatMessagesHash() => r'962cb17b54520895ebdb19e2f6abd9e17964a4cd';

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

/// See also [chatMessages].
@ProviderFor(chatMessages)
const chatMessagesProvider = ChatMessagesFamily();

/// See also [chatMessages].
class ChatMessagesFamily extends Family<AsyncValue<List<ChatMessageModel>>> {
  /// See also [chatMessages].
  const ChatMessagesFamily();

  /// See also [chatMessages].
  ChatMessagesProvider call(String sessionId) {
    return ChatMessagesProvider(sessionId);
  }

  @override
  ChatMessagesProvider getProviderOverride(
    covariant ChatMessagesProvider provider,
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
  String? get name => r'chatMessagesProvider';
}

/// See also [chatMessages].
class ChatMessagesProvider
    extends AutoDisposeFutureProvider<List<ChatMessageModel>> {
  /// See also [chatMessages].
  ChatMessagesProvider(String sessionId)
    : this._internal(
        (ref) => chatMessages(ref as ChatMessagesRef, sessionId),
        from: chatMessagesProvider,
        name: r'chatMessagesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$chatMessagesHash,
        dependencies: ChatMessagesFamily._dependencies,
        allTransitiveDependencies:
            ChatMessagesFamily._allTransitiveDependencies,
        sessionId: sessionId,
      );

  ChatMessagesProvider._internal(
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
    FutureOr<List<ChatMessageModel>> Function(ChatMessagesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ChatMessagesProvider._internal(
        (ref) => create(ref as ChatMessagesRef),
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
    return _ChatMessagesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatMessagesProvider && other.sessionId == sessionId;
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
mixin ChatMessagesRef on AutoDisposeFutureProviderRef<List<ChatMessageModel>> {
  /// The parameter `sessionId` of this provider.
  String get sessionId;
}

class _ChatMessagesProviderElement
    extends AutoDisposeFutureProviderElement<List<ChatMessageModel>>
    with ChatMessagesRef {
  _ChatMessagesProviderElement(super.provider);

  @override
  String get sessionId => (origin as ChatMessagesProvider).sessionId;
}

String _$actionLogsHash() => r'7820ce9f34f3a7bfe22f62aa6e5defb7a6795c02';

/// See also [actionLogs].
@ProviderFor(actionLogs)
const actionLogsProvider = ActionLogsFamily();

/// See also [actionLogs].
class ActionLogsFamily extends Family<AsyncValue<List<ActionLogModel>>> {
  /// See also [actionLogs].
  const ActionLogsFamily();

  /// See also [actionLogs].
  ActionLogsProvider call(String sessionId) {
    return ActionLogsProvider(sessionId);
  }

  @override
  ActionLogsProvider getProviderOverride(
    covariant ActionLogsProvider provider,
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
  String? get name => r'actionLogsProvider';
}

/// See also [actionLogs].
class ActionLogsProvider
    extends AutoDisposeFutureProvider<List<ActionLogModel>> {
  /// See also [actionLogs].
  ActionLogsProvider(String sessionId)
    : this._internal(
        (ref) => actionLogs(ref as ActionLogsRef, sessionId),
        from: actionLogsProvider,
        name: r'actionLogsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$actionLogsHash,
        dependencies: ActionLogsFamily._dependencies,
        allTransitiveDependencies: ActionLogsFamily._allTransitiveDependencies,
        sessionId: sessionId,
      );

  ActionLogsProvider._internal(
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
    FutureOr<List<ActionLogModel>> Function(ActionLogsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ActionLogsProvider._internal(
        (ref) => create(ref as ActionLogsRef),
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
    return _ActionLogsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ActionLogsProvider && other.sessionId == sessionId;
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
mixin ActionLogsRef on AutoDisposeFutureProviderRef<List<ActionLogModel>> {
  /// The parameter `sessionId` of this provider.
  String get sessionId;
}

class _ActionLogsProviderElement
    extends AutoDisposeFutureProviderElement<List<ActionLogModel>>
    with ActionLogsRef {
  _ActionLogsProviderElement(super.provider);

  @override
  String get sessionId => (origin as ActionLogsProvider).sessionId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
