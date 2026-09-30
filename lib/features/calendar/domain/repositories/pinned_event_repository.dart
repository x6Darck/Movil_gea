import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/event.dart';

abstract class PinnedEventRepository {
  Future<Either<Failure, List<Event>>> getPinnedEvents();
  Future<Either<Failure, Unit>> pinEvent(String eventId);
  Future<Either<Failure, Unit>> unpinEvent(String eventId);
}
