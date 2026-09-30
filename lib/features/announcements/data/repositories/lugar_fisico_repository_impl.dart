import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gea_app/core/error/dio_error_mapper.dart';
import 'package:gea_app/core/error/failures.dart';
import '../../domain/repositories/lugar_fisico_repository.dart';
import '../models/lugar_fisico_model.dart';

class LugarFisicoRepositoryImpl implements LugarFisicoRepository {
  final Dio _dio;

  LugarFisicoRepositoryImpl(this._dio);

  @override
  Future<Either<Failure, List<LugarFisicoModel>>> getLugaresFisicos() async {
    try {
      final response = await _dio.get('/lugares-fisicos');
      final data = response.data;
      if (data != null && data['success'] == true) {
        final List<dynamic> list = data['data'] ?? [];
        final lugares = list.map((e) => LugarFisicoModel.fromJson(e)).toList();
        return Right(lugares);
      }
      return const Left(ServerFailure('Error al obtener lugares físicos'));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return const Left(ServerFailure('Sesión expirada. Por favor, inicia sesión.'));
      }
      return Left(ServerFailure(friendlyDioMessage(
        e,
        fallback: 'No se pudieron cargar los lugares físicos. Intenta de nuevo.',
      )));
    } catch (e) {
      return const Left(ServerFailure('Ocurrió un error inesperado. Intenta de nuevo.'));
    }
  }
}
