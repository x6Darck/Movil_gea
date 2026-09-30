import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/dio_error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/offline_cache_service.dart';
import '../../domain/entities/event.dart';
import '../../domain/repositories/event_repository.dart';
import '../models/event_model.dart';

class EventRepositoryImpl implements EventRepository {
  final Dio _dio;
  final OfflineCacheService _cache;

  EventRepositoryImpl(this._dio, this._cache);

  @override
  Future<Either<Failure, List<Event>>> getEvents() async {
    try {
      final response = await _dio.get('/app/eventos/publicados');
      final data = response.data['data'] as List? ?? [];
      await _cache.saveEvents(data);
      final events = data
          .map((json) => EventModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return Right(events);
    } on DioException catch (e) {
      if (e.response == null) {
        final cached = await _cache.loadEvents();
        if (cached != null) {
          final events = cached
              .map((json) => EventModel.fromJson(json as Map<String, dynamic>))
              .toList();
          return Right(events);
        }
      }
      return Left(ServerFailure(friendlyDioMessage(
        e,
        fallback: 'No se pudieron cargar los eventos. Intenta de nuevo.',
      )));
    } catch (e) {
      return const Left(ServerFailure('Ocurrió un error inesperado. Intenta de nuevo.'));
    }
  }

  @override
  Future<Either<Failure, List<Event>>> getEventsByDate(DateTime date) async {
    final result = await getEvents();
    return result.map((events) => events
        .where((e) =>
            e.date.year == date.year &&
            e.date.month == date.month &&
            e.date.day == date.day)
        .toList());
  }
}
