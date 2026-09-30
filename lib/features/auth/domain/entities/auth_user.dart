import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  final String id;
  final String email;
  final String name;
  final String token;
  final String role;

  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
    required this.token,
    required this.role,
  });

  /// Nombre de rol legible para mostrar en la UI.
  String get roleDisplayName {
    switch (role.toUpperCase()) {
      case 'SUPER_ADMIN':
      case 'ADMIN':
        return 'Super Administrador';
      case 'COMUNICACIONES':
        return 'Comunicaciones';
      case 'OFICINA':
        return 'Oficina / Dependencia';
      case 'USUARIO_AUTENTICADO_APP':
        return 'Estudiante';
      default:
        return 'Usuario General';
    }
  }

  @override
  List<Object?> get props => [id, email, name, token, role];
}
