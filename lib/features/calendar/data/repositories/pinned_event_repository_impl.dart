import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/dio_error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/event.dart';
import '../../domain/repositories/pinned_event_repository.dart';
import '../datasources/pinned_event_remote_datasource.dart';

class PinnedEventRepositoryImpl implements PinnedEventRepository {
  final PinnedEventRemoteDatasource _datasource;
  PinnedEventRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, List<Event>>> getPinnedEvents() async {
    try {
      final events = await _datasource.getPinnedEvents();
      return Right(events);
    } on DioException catch (e) {
      return Left(ServerFailure(friendlyDioMessage(
        e,
        fallback: 'No se pudieron cargar tus eventos fijados. Intenta de nuevo.',
      )));
    } catch (e) {
      return const Left(ServerFailure('Ocurrió un error inesperado. Intenta de nuevo.'));
    }
  }

  @override
  Future<Either<Failure, Unit>> pinEvent(String eventId) async {
    try {
      await _datasource.pinEvent(eventId);
      return const Right(unit);
    } on DioException catch (e) {
      return Left(ServerFailure(friendlyDioMessage(
        e,
        fallback: 'No se pudo fijar el evento. Intenta de nuevo.',
      )));
    } catch (e) {
      return const Left(ServerFailure('Ocurrió un error inesperado. Intenta de nuevo.'));
    }
  }

  @override
  Future<Either<Failure, Unit>> unpinEvent(String eventId) async {
    try {
      await _datasource.unpinEvent(eventId);
      return const Right(unit);
    } on DioException catch (e) {
      return Left(ServerFailure(friendlyDioMessage(
        e,
        fallback: 'No se pudo quitar el evento fijado. Intenta de nuevo.',
      )));
    } catch (e) {
      return const Left(ServerFailure('Ocurrió un error inesperado. Intenta de nuevo.'));
    }
  }
}
