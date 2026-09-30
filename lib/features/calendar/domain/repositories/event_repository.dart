import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/event.dart';

abstract class EventRepository {
  Future<Either<Failure, List<Event>>> getEvents();
  Future<Either<Failure, List<Event>>> getEventsByDate(DateTime date);
}
