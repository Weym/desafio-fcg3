import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/dio_provider.dart';
import '../models/staff_member_model.dart';
import '../services/staff_management_service.dart';

part 'staff_management_provider.g.dart';

@Riverpod(keepAlive: true)
StaffManagementService staffManagementService(Ref ref) {
  final client = ref.watch(dioClientProvider);
  return StaffManagementService(client: client);
}

@riverpod
class StaffMemberList extends _$StaffMemberList {
  String? _search;
  String? _statusFilter;

  @override
  Future<List<StaffMemberModel>> build() async {
    return _fetch();
  }

  Future<List<StaffMemberModel>> _fetch() async {
    final service = ref.read(staffManagementServiceProvider);
    final result = await service.listStaff(
      search: _search,
      status: _statusFilter,
    );
    return result.items;
  }

  Future<void> setSearch(String? search) async {
    _search = search;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> setStatusFilter(String? status) async {
    _statusFilter = status;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> createMember(Map<String, dynamic> data) async {
    final service = ref.read(staffManagementServiceProvider);
    await service.createStaff(data);
    await refresh();
  }

  Future<void> updateMember(String id, Map<String, dynamic> data) async {
    final service = ref.read(staffManagementServiceProvider);
    await service.updateStaff(id, data);
    await refresh();
  }

  Future<void> deleteMember(String id) async {
    final service = ref.read(staffManagementServiceProvider);
    await service.deleteStaff(id);
    await refresh();
  }
}
