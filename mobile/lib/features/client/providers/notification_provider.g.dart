// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$derivedNotificationsHash() =>
    r'2e21dbaf0060eb2857dbf66024bc9fa0e3cad4a8';

/// See also [derivedNotifications].
@ProviderFor(derivedNotifications)
final derivedNotificationsProvider =
    AutoDisposeFutureProvider<List<DerivedNotification>>.internal(
      derivedNotifications,
      name: r'derivedNotificationsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$derivedNotificationsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DerivedNotificationsRef =
    AutoDisposeFutureProviderRef<List<DerivedNotification>>;
String _$readNotificationIdsHash() =>
    r'd6f42fbbc5edc7e480bfab58cd3d06e57440f171';

/// See also [ReadNotificationIds].
@ProviderFor(ReadNotificationIds)
final readNotificationIdsProvider =
    AutoDisposeNotifierProvider<ReadNotificationIds, Set<String>>.internal(
      ReadNotificationIds.new,
      name: r'readNotificationIdsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$readNotificationIdsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ReadNotificationIds = AutoDisposeNotifier<Set<String>>;
String _$notificationFilterNotifierHash() =>
    r'db59c3bb1ae13493d81a7ce44162d5d96bf86ce5';

/// See also [NotificationFilterNotifier].
@ProviderFor(NotificationFilterNotifier)
final notificationFilterNotifierProvider =
    AutoDisposeNotifierProvider<
      NotificationFilterNotifier,
      NotificationFilter
    >.internal(
      NotificationFilterNotifier.new,
      name: r'notificationFilterNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$notificationFilterNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$NotificationFilterNotifier = AutoDisposeNotifier<NotificationFilter>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
