// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_tokens.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
  accessToken: json['access_token'] as String,
  refreshToken: json['refresh_token'] as String,
  tokenType: json['token_type'] as String,
  expiresIn: (json['expires_in'] as num).toInt(),
);

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
      'token_type': instance.tokenType,
      'expires_in': instance.expiresIn,
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
