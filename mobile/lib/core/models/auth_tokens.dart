import 'package:json_annotation/json_annotation.dart';
import 'user_model.dart';

part 'auth_tokens.g.dart';

@JsonSerializable()
class AuthResponse {
  final String token;
  final UserModel user;
  @JsonKey(name: 'expires_at')
  final String expiresAt;
  @JsonKey(name: 'refresh_token')
  final String? refreshToken;

  const AuthResponse({
    required this.token,
    required this.user,
    required this.expiresAt,
    this.refreshToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

@JsonSerializable()
class RequestCodeResponse {
  final String message;
  @JsonKey(name: 'expires_in')
  final int expiresIn;

  const RequestCodeResponse({
    required this.message,
    required this.expiresIn,
  });

  factory RequestCodeResponse.fromJson(Map<String, dynamic> json) =>
      _$RequestCodeResponseFromJson(json);
  Map<String, dynamic> toJson() => _$RequestCodeResponseToJson(this);
}
