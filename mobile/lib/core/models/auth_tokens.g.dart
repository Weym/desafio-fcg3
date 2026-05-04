// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_tokens.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
  token: json['token'] as String,
  user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
  expiresAt: json['expires_at'] as String,
  refreshToken: json['refresh_token'] as String?,
);

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{
      'token': instance.token,
      'user': instance.user,
      'expires_at': instance.expiresAt,
      'refresh_token': instance.refreshToken,
    };

RequestCodeResponse _$RequestCodeResponseFromJson(Map<String, dynamic> json) =>
    RequestCodeResponse(
      message: json['message'] as String,
      expiresIn: (json['expires_in'] as num).toInt(),
    );

Map<String, dynamic> _$RequestCodeResponseToJson(
  RequestCodeResponse instance,
) => <String, dynamic>{
  'message': instance.message,
  'expires_in': instance.expiresIn,
};
