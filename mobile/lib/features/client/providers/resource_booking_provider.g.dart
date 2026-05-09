// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resource_booking_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$resourceBookingServiceHash() =>
    r'83408d9ff0d732efe396e1fec64dcbd69cb13128';

/// See also [resourceBookingService].
@ProviderFor(resourceBookingService)
final resourceBookingServiceProvider =
    Provider<ResourceBookingService>.internal(
      resourceBookingService,
      name: r'resourceBookingServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$resourceBookingServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ResourceBookingServiceRef = ProviderRef<ResourceBookingService>;
String _$availableResourcesHash() =>
    r'39603e26609c3b3503cf932895f8c80b3f40c830';

/// See also [availableResources].
@ProviderFor(availableResources)
final availableResourcesProvider =
    AutoDisposeFutureProvider<List<ClientResourceModel>>.internal(
      availableResources,
      name: r'availableResourcesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$availableResourcesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AvailableResourcesRef =
    AutoDisposeFutureProviderRef<List<ClientResourceModel>>;
String _$resourceSlotsHash() => r'b1ff5c9b35c4fed43f78e00de97d7cf25db04273';

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

/// See also [resourceSlots].
@ProviderFor(resourceSlots)
const resourceSlotsProvider = ResourceSlotsFamily();

/// See also [resourceSlots].
class ResourceSlotsFamily
    extends Family<AsyncValue<List<SchedulingSlotModel>>> {
  /// See also [resourceSlots].
  const ResourceSlotsFamily();

  /// See also [resourceSlots].
  ResourceSlotsProvider call(String resourceId) {
    return ResourceSlotsProvider(resourceId);
  }

  @override
  ResourceSlotsProvider getProviderOverride(
    covariant ResourceSlotsProvider provider,
  ) {
    return call(provider.resourceId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'resourceSlotsProvider';
}

/// See also [resourceSlots].
class ResourceSlotsProvider
    extends AutoDisposeFutureProvider<List<SchedulingSlotModel>> {
  /// See also [resourceSlots].
  ResourceSlotsProvider(String resourceId)
    : this._internal(
        (ref) => resourceSlots(ref as ResourceSlotsRef, resourceId),
        from: resourceSlotsProvider,
        name: r'resourceSlotsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$resourceSlotsHash,
        dependencies: ResourceSlotsFamily._dependencies,
        allTransitiveDependencies:
            ResourceSlotsFamily._allTransitiveDependencies,
        resourceId: resourceId,
      );

  ResourceSlotsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.resourceId,
  }) : super.internal();

  final String resourceId;

  @override
  Override overrideWith(
    FutureOr<List<SchedulingSlotModel>> Function(ResourceSlotsRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ResourceSlotsProvider._internal(
        (ref) => create(ref as ResourceSlotsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        resourceId: resourceId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<SchedulingSlotModel>> createElement() {
    return _ResourceSlotsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ResourceSlotsProvider && other.resourceId == resourceId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, resourceId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ResourceSlotsRef
    on AutoDisposeFutureProviderRef<List<SchedulingSlotModel>> {
  /// The parameter `resourceId` of this provider.
  String get resourceId;
}

class _ResourceSlotsProviderElement
    extends AutoDisposeFutureProviderElement<List<SchedulingSlotModel>>
    with ResourceSlotsRef {
  _ResourceSlotsProviderElement(super.provider);

  @override
  String get resourceId => (origin as ResourceSlotsProvider).resourceId;
}

String _$resourceTypeFilterHash() =>
    r'ec25a2196f8dd5400e606c6da46e1a2f69bedc78';

/// See also [ResourceTypeFilter].
@ProviderFor(ResourceTypeFilter)
final resourceTypeFilterProvider =
    AutoDisposeNotifierProvider<ResourceTypeFilter, String?>.internal(
      ResourceTypeFilter.new,
      name: r'resourceTypeFilterProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$resourceTypeFilterHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ResourceTypeFilter = AutoDisposeNotifier<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
