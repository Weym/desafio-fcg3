// Phase 12, Plan 02 — GAP-12-02-A: Auth contract tests.
//
// Validates that Dart auth models parse the exact JSON shapes emitted by
// the FastAPI backend (backend is source of truth, per D-02):
//   - TokenPair (backend/src/features/auth/schemas.py::TokenPair)
//   - RequestCodeResponse (backend/src/features/auth/schemas.py::RequestCodeResponse)
//   - MeResponse (backend/src/features/auth/schemas.py::MeResponse)
//
// These tests use JSON literals only — they do NOT touch the network or
// the Docker stack. Run with: `cd mobile && flutter test test/contracts/`.

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/models/auth_tokens.dart';
import 'package:frontend/core/models/user_model.dart';

void main() {
  group('TokenPair contract (backend schemas.py::TokenPair)', () {
    test('fromJson parses all four required fields from backend JSON', () {
      // Shape exactly as emitted by POST /auth/verify-code and /auth/refresh.
      final json = <String, dynamic>{
        'access_token': 'eyJhbGciOiJIUzI1NiJ9.access.sig',
        'refresh_token': 'eyJhbGciOiJIUzI1NiJ9.refresh.sig',
        'token_type': 'bearer',
        'expires_in': 3600,
      };

      final response = AuthResponse.fromJson(json);

      expect(response.accessToken, 'eyJhbGciOiJIUzI1NiJ9.access.sig');
      expect(response.refreshToken, 'eyJhbGciOiJIUzI1NiJ9.refresh.sig');
      expect(response.tokenType, 'bearer');
      expect(response.expiresIn, 3600);
    });

    test('toJson round-trips to backend snake_case keys (no camelCase leak)', () {
      const response = AuthResponse(
        accessToken: 'at',
        refreshToken: 'rt',
        tokenType: 'bearer',
        expiresIn: 3600,
      );

      final serialized = response.toJson();
      // Exact snake_case keys — anything else breaks backend interop.
      expect(serialized.keys.toSet(), {
        'access_token',
        'refresh_token',
        'token_type',
        'expires_in',
      });
      // Sanity: no accidental camelCase leak.
      expect(serialized.containsKey('accessToken'), isFalse);
      expect(serialized.containsKey('refreshToken'), isFalse);
      expect(serialized.containsKey('tokenType'), isFalse);
      expect(serialized.containsKey('expiresIn'), isFalse);
    });

    test('fromJson preserves a non-default token_type if backend changes it', () {
      // Default is "bearer"; guard against silent default drift.
      final response = AuthResponse.fromJson(const {
        'access_token': 'a',
        'refresh_token': 'r',
        'token_type': 'Bearer', // capitalization variation
        'expires_in': 7200,
      });
      expect(response.tokenType, 'Bearer');
      expect(response.expiresIn, 7200);
    });
  });

  group('RequestCodeResponse contract (schemas.py::RequestCodeResponse)', () {
    test('fromJson parses POST /auth/request-code response shape', () {
      final json = <String, dynamic>{
        'message': 'Codigo enviado',
        'expires_in': 300,
      };

      final response = RequestCodeResponse.fromJson(json);

      expect(response.message, 'Codigo enviado');
      expect(response.expiresIn, 300);
    });

    test('toJson emits snake_case expires_in key (not camelCase)', () {
      const response = RequestCodeResponse(
        message: 'Codigo enviado',
        expiresIn: 300,
      );
      final json = response.toJson();
      expect(json.keys.toSet(), {'message', 'expires_in'});
    });
  });

  group('UserModel contract (schemas.py::MeResponse)', () {
    test('fromJson parses GET /auth/me canonical response', () {
      // Exactly MeResponse fields: id, email, name, role.
      final user = UserModel.fromJson(const {
        'id': 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
        'email': 'henrygabrielandradeoliveira@gmail.com',
        'name': 'Henry Gabriel',
        'role': 'student',
      });

      expect(user.id, 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee');
      expect(user.email, 'henrygabrielandradeoliveira@gmail.com');
      expect(user.name, 'Henry Gabriel');
      expect(user.role, 'student');
      expect(user.isStudent, isTrue);
      expect(user.isStaff, isFalse);
      expect(user.phone, isNull);
    });

    test('fromJson accepts staff role and convenience flags flip', () {
      final user = UserModel.fromJson(const {
        'id': '1',
        'email': 'universalblackout1@gmail.com',
        'name': 'Henry (Staff)',
        'role': 'staff',
      });
      expect(user.isStaff, isTrue);
      expect(user.isStudent, isFalse);
    });

    test('fromJson tolerates legacy "type" key via readValue fallback', () {
      // UserModel has a readValue bridge from "type" → "role" for older
      // payloads. Guards against regressions if the bridge is removed.
      final user = UserModel.fromJson(const {
        'id': '2',
        'email': 'legacy@test.invalid',
        'name': 'Legacy Payload',
        'type': 'staff',
      });
      expect(user.role, 'staff');
    });

    test('fromJson accepts optional phone without exception', () {
      final user = UserModel.fromJson(const {
        'id': '3',
        'email': 'with.phone@test.invalid',
        'name': 'With Phone',
        'role': 'student',
        'phone': '5511999999999',
      });
      expect(user.phone, '5511999999999');
    });
  });
}
