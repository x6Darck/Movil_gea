import 'package:dio/dio.dart';
import '../models/event_model.dart';
import '../../domain/entities/event.dart';

class PinnedEventRemoteDatasource {
  final Dio _dio;
  PinnedEventRemoteDatasource(this._dio);

  Future<List<Event>> getPinnedEvents() async {
    final response = await _dio.get('/app/eventos/fijados');
    final data = response.data['data'] as List? ?? [];
    return data.map((json) => EventModel.fromJson(json)).toList();
  }

  Future<void> pinEvent(String eventId) async {
    await _dio.post('/app/eventos/fijados/$eventId');
  }

  Future<void> unpinEvent(String eventId) async {
    await _dio.delete('/app/eventos/fijados/$eventId');
  }
}
