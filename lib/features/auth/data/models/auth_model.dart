import 'dart:convert';
import '../../domain/entities/auth_user.dart';

class AuthModel extends AuthUser {
  const AuthModel({
    required super.id,
    required super.email,
    required super.name,
    required super.token,
    required super.role,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    final token = json['token']?.toString() ?? '';
    final payload = _decodeJwtPayload(token);

    return AuthModel(
      id: json['id']?.toString() ?? payload['id']?.toString() ?? '',
      email: json['correo']?.toString() ??
          json['email']?.toString() ??
          payload['sub']?.toString() ??
          '',
      name: json['nombre']?.toString() ?? json['name']?.toString() ?? '',
      token: token,
      role: payload['rol']?.toString() ?? 'USUARIO_APP',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'token': token,
      'role': role,
    };
  }

  /// Decodifica el payload del JWT sin verificar la firma.
  /// Solo para extraer claims no sensibles (rol, id) en el cliente.
  static Map<String, dynamic> _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return {};
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return json.decode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
