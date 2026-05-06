// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_resource_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$staffResourceServiceHash() =>
    r'2f4540b1368ab8388424dfb7c90ff00e51a92d98';

/// See also [staffResourceService].
@ProviderFor(staffResourceService)
final staffResourceServiceProvider = Provider<StaffResourceService>.internal(
  staffResourceService,
  name: r'staffResourceServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$staffResourceServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StaffResourceServiceRef = ProviderRef<StaffResourceService>;
String _$staffResourcesHash() => r'd322a3cd50b4e02277f96ab0b05b8ea84a45dfd2';

/// See also [staffResources].
@ProviderFor(staffResources)
final staffResourcesProvider =
    AutoDisposeFutureProvider<List<ResourceModel>>.internal(
      staffResources,
      name: r'staffResourcesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$staffResourcesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StaffResourcesRef = AutoDisposeFutureProviderRef<List<ResourceModel>>;
String _$staffResourceTypeFilterHash() =>
    r'8eedd6c035b9d159c7d69c0dbed3877cff7a76e8';

/// See also [StaffResourceTypeFilter].
@ProviderFor(StaffResourceTypeFilter)
final staffResourceTypeFilterProvider =
    AutoDisposeNotifierProvider<StaffResourceTypeFilter, String?>.internal(
      StaffResourceTypeFilter.new,
      name: r'staffResourceTypeFilterProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$staffResourceTypeFilterHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$StaffResourceTypeFilter = AutoDisposeNotifier<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
