import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/auth/services/auth_service.dart';
import '../network/dio_client.dart';
import 'storage_provider.dart';

part 'dio_provider.g.dart';

@Riverpod(keepAlive: true)
DioClient dioClient(Ref ref) {
  final storage = ref.watch(flutterSecureStorageProvider);
  return DioClient(storage: storage);
}

@Riverpod(keepAlive: true)
AuthService authService(Ref ref) {
  final client = ref.watch(dioClientProvider);
  return AuthService(client: client);
}
