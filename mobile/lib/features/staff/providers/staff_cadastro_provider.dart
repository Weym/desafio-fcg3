import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/dio_provider.dart';
import '../../../core/providers/cache_provider.dart';
import '../models/staff_student_model.dart';
import '../services/staff_cadastro_service.dart';

part 'staff_cadastro_provider.g.dart';

@Riverpod(keepAlive: true)
StaffCadastroService staffCadastroService(Ref ref) {
  final client = ref.watch(dioClientProvider);
  return StaffCadastroService(client: client);
}

@riverpod
Future<List<StaffStudentModel>> staffStudents(Ref ref) async {
  final service = ref.watch(staffCadastroServiceProvider);
  final students = await service.getStudents();
  CacheTTL.schedule(ref, 'staffStudents');
  return students;
}

@riverpod
class StaffCadastroFilter extends _$StaffCadastroFilter {
  @override
  String? build() => null; // null = "Todos"

  void setFilter(String? filter) => state = filter;
}

@riverpod
class StaffCadastroSearch extends _$StaffCadastroSearch {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}
