// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_schedule_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$staffScheduleServiceHash() =>
    r'9b3a3fb50961ef0cc8380a902ac08e3a0e19c6fe';

/// See also [staffScheduleService].
@ProviderFor(staffScheduleService)
final staffScheduleServiceProvider = Provider<StaffScheduleService>.internal(
  staffScheduleService,
  name: r'staffScheduleServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$staffScheduleServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StaffScheduleServiceRef = ProviderRef<StaffScheduleService>;
String _$staffAppointmentsHash() => r'c6272d3a279afaeb055a288aaf97c2417f549352';

/// See also [staffAppointments].
@ProviderFor(staffAppointments)
final staffAppointmentsProvider =
    AutoDisposeFutureProvider<List<AppointmentModel>>.internal(
      staffAppointments,
      name: r'staffAppointmentsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$staffAppointmentsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StaffAppointmentsRef =
    AutoDisposeFutureProviderRef<List<AppointmentModel>>;
String _$staffSlotsHash() => r'cea91160d62ff19e1253bea340898b5684d80159';

/// See also [staffSlots].
@ProviderFor(staffSlots)
final staffSlotsProvider =
    AutoDisposeFutureProvider<List<SchedulingSlotModel>>.internal(
      staffSlots,
      name: r'staffSlotsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$staffSlotsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef StaffSlotsRef = AutoDisposeFutureProviderRef<List<SchedulingSlotModel>>;
String _$staffScheduleFilterHash() =>
    r'2b42f967be1550e1c7d9e1128300a0367aa3b214';

/// See also [StaffScheduleFilter].
@ProviderFor(StaffScheduleFilter)
final staffScheduleFilterProvider =
    AutoDisposeNotifierProvider<StaffScheduleFilter, String?>.internal(
      StaffScheduleFilter.new,
      name: r'staffScheduleFilterProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$staffScheduleFilterHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$StaffScheduleFilter = AutoDisposeNotifier<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
