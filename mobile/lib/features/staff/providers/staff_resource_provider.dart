import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/dio_provider.dart';
import '../../../core/providers/cache_provider.dart';
import '../models/resource_model.dart';
import '../services/staff_resource_service.dart';

part 'staff_resource_provider.g.dart';

@Riverpod(keepAlive: true)
StaffResourceService staffResourceService(Ref ref) {
  final client = ref.watch(dioClientProvider);
  return StaffResourceService(client: client);
}

@riverpod
Future<List<ResourceModel>> staffResources(Ref ref) async {
  final service = ref.watch(staffResourceServiceProvider);
  final resources = await service.getResources();
  CacheTTL.schedule(ref, 'staffResources');
  return resources;
}

@riverpod
class StaffResourceTypeFilter extends _$StaffResourceTypeFilter {
  @override
  String? build() => null; // null = "Todos"

  void setFilter(String? type) => state = type;
}
