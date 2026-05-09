// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_cadastro_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$staffCadastroServiceHash() =>
    r'e8198c705b29f12f980602c250a4cd0f1affcc6d';

/// See also [staffCadastroService].
@ProviderFor(staffCadastroService)
final staffCadastroServiceProvider = Provider<StaffCadastroService>.internal(
  staffCadastroService,
  name: r'staffCadastroServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$staffCadastroServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StaffCadastroServiceRef = ProviderRef<StaffCadastroService>;
String _$staffStudentsHash() => r'7be0fbd2a2acd6d3f67e270c75fc012412d8e15f';

/// See also [staffStudents].
@ProviderFor(staffStudents)
final staffStudentsProvider =
    AutoDisposeFutureProvider<List<StaffStudentModel>>.internal(
      staffStudents,
      name: r'staffStudentsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$staffStudentsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StaffStudentsRef =
    AutoDisposeFutureProviderRef<List<StaffStudentModel>>;
String _$staffCadastroFilterHash() =>
    r'eba175c3ac2397fe4c34a110e38ee12a9553db0b';

/// See also [StaffCadastroFilter].
@ProviderFor(StaffCadastroFilter)
final staffCadastroFilterProvider =
    AutoDisposeNotifierProvider<StaffCadastroFilter, String?>.internal(
      StaffCadastroFilter.new,
      name: r'staffCadastroFilterProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$staffCadastroFilterHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$StaffCadastroFilter = AutoDisposeNotifier<String?>;
String _$staffCadastroSearchHash() =>
    r'b9266e7d315846d78e9ff883f574e0a265e6c874';

/// See also [StaffCadastroSearch].
@ProviderFor(StaffCadastroSearch)
final staffCadastroSearchProvider =
    AutoDisposeNotifierProvider<StaffCadastroSearch, String>.internal(
      StaffCadastroSearch.new,
      name: r'staffCadastroSearchProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$staffCadastroSearchHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$StaffCadastroSearch = AutoDisposeNotifier<String>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
