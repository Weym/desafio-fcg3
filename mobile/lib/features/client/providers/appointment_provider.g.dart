// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointment_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appointmentServiceHash() =>
    r'e0f5f0df76125b3c2d58d6de664b804e326b7721';

/// See also [appointmentService].
@ProviderFor(appointmentService)
final appointmentServiceProvider = Provider<AppointmentService>.internal(
  appointmentService,
  name: r'appointmentServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appointmentServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppointmentServiceRef = ProviderRef<AppointmentService>;
String _$appointmentsHash() => r'30429a4384535e48ea2a35052e24b93877a7cb80';

/// See also [appointments].
@ProviderFor(appointments)
final appointmentsProvider =
    AutoDisposeFutureProvider<List<AppointmentModel>>.internal(
      appointments,
      name: r'appointmentsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$appointmentsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppointmentsRef = AutoDisposeFutureProviderRef<List<AppointmentModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
