import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fpdart/fpdart.dart';
import 'package:aad_oauth/request_code.dart';
import '../../../../core/error/dio_error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/auth_model.dart';
import 'package:gea_app/core/config/microsoft_auth_config.dart';

class AuthRepositoryImpl implements AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  AuthRepositoryImpl(this._dio, this._storage);

  @override
  Future<Either<Failure, AuthUser>> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'correo': email,
        'password': password,
      });

      final authModel = AuthModel.fromJson(response.data['data'] ?? response.data);
      
      // Save token securely
      await _storage.write(key: 'jwt_token', value: authModel.token);
      
      return Right(authModel);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return const Left(AuthFailure('Correo o contraseña incorrectos'));
      }
      if (e.response?.statusCode == 400) {
        // Validation errors from backend usually come inside response.data
        final data = e.response?.data;
        String msg = 'Solicitud inválida. Revisa los datos.';
        if (data != null && data is Map && data.containsKey('message')) {
          msg = data['message'];
        }
        return Left(AuthFailure(msg));
      }
      return Left(ServerFailure(friendlyDioMessage(
        e,
        fallback: 'Error del servidor o de red. Intenta más tarde.',
      )));
    } catch (e) {
      return const Left(ServerFailure('Ocurrió un error inesperado.'));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> loginWithMicrosoft() async {
    try {
      // 1. Login interactivo con Microsoft, capturando SOLO el código de
      // autorización (RequestCode, no AadOAuth.login()/getIdToken()). El
      // registro de "GeaApp" en Azure es cliente confidencial (sin "Allow
      // public client flows"): el intercambio código→token que hace
      // AadOAuth internamente no manda client_secret y Microsoft lo
      // rechaza. El intercambio real ocurre en el backend, que sí tiene el
      // secret (nunca debe vivir en el APK — es extraíble descompilándolo).
      final String? code =
          await RequestCode(MicrosoftAuthConfig.config).requestCode();
      if (code == null) {
        return const Left(AuthFailure('Inicio de sesión con Microsoft cancelado.'));
      }

      // 2. Enviar el código al backend de GEA — el backend lo cambia por el
      // idToken con el client_secret y lo valida.
      final response = await _dio.post('/auth/microsoft/mobile/code', data: {
        'code': code,
      });

      final authModel = AuthModel.fromJson(response.data['data'] ?? response.data);
      
      // Guardar el token JWT de GEA en el almacenamiento seguro
      await _storage.write(key: 'jwt_token', value: authModel.token);
      
      return Right(authModel);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return const Left(AuthFailure('Sesión de Microsoft denegada o inválida.'));
      }
      if (e.response?.statusCode == 501) {
        return const Left(ServerFailure('Autenticación con Microsoft no habilitada en el servidor.'));
      }
      if (e.response?.statusCode == 400) {
        final data = e.response?.data;
        String msg = 'Token de Microsoft mal estructurado.';
        if (data != null && data is Map && data.containsKey('message')) {
          msg = data['message'];
        }
        return Left(AuthFailure(msg));
      }
      return Left(ServerFailure(friendlyDioMessage(
        e,
        fallback: 'Error de servidor o red al validar con Microsoft.',
      )));
    } catch (e) {
      return const Left(AuthFailure('Error inesperado al autenticar con Microsoft.'));
    }
  }

  @override
  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    try {
      await MicrosoftAuthConfig.oauth.logout();
    } catch (_) {
      // Ignorar fallas al cerrar sesión en Microsoft para no bloquear el flujo principal
    }
  }

  @override
  Future<Option<AuthUser>> getCurrentUser() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return const None();
    
    // In a real app, you might want to fetch user profile or decode JWT
    // For now, if token exists, we assume logged in (minimalist approach)
    return const None(); // Implementation depends on backend /profile endpoint
  }
}
