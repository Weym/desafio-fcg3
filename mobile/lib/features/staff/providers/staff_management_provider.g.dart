// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_management_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$staffManagementServiceHash() =>
    r'c0f613d02f106ab980597722c5c977aa49aff6ca';

/// See also [staffManagementService].
@ProviderFor(staffManagementService)
final staffManagementServiceProvider =
    Provider<StaffManagementService>.internal(
      staffManagementService,
      name: r'staffManagementServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$staffManagementServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StaffManagementServiceRef = ProviderRef<StaffManagementService>;
String _$staffMemberListHash() => r'481434cb2e433c16871cf197b5c1646ba97c4959';

/// See also [StaffMemberList].
@ProviderFor(StaffMemberList)
final staffMemberListProvider =
    AutoDisposeAsyncNotifierProvider<
      StaffMemberList,
      List<StaffMemberModel>
    >.internal(
      StaffMemberList.new,
      name: r'staffMemberListProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$staffMemberListHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$StaffMemberList = AutoDisposeAsyncNotifier<List<StaffMemberModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
