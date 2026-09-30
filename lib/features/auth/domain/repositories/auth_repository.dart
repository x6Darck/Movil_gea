import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/auth_user.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthUser>> login(String email, String password);
  Future<Either<Failure, AuthUser>> loginWithMicrosoft();
  Future<void> logout();
  Future<Option<AuthUser>> getCurrentUser();
}
