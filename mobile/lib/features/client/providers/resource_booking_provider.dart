import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/dio_provider.dart';
import '../../../core/providers/cache_provider.dart';
import '../models/resource_model.dart';
import '../services/resource_booking_service.dart';
import '../../staff/models/scheduling_slot_model.dart';

part 'resource_booking_provider.g.dart';

@Riverpod(keepAlive: true)
ResourceBookingService resourceBookingService(Ref ref) {
  final client = ref.watch(dioClientProvider);
  return ResourceBookingService(client: client);
}

@riverpod
Future<List<ClientResourceModel>> availableResources(Ref ref) async {
  final service = ref.watch(resourceBookingServiceProvider);
  final filter = ref.watch(resourceTypeFilterProvider);
  final resources = await service.getAvailableResources(resourceType: filter);
  CacheTTL.schedule(ref, 'availableResources');
  return resources;
}

@riverpod
class ResourceTypeFilter extends _$ResourceTypeFilter {
  @override
  String? build() => null;

  void setFilter(String? type) {
    state = type;
  }
}

@riverpod
Future<List<SchedulingSlotModel>> resourceSlots(Ref ref, String resourceId) async {
  final service = ref.watch(resourceBookingServiceProvider);
  return service.getSlotsForResource(resourceId);
}
