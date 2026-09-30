import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/event.dart';
import '../repositories/pinned_event_repository.dart';

class GetPinnedEventsUseCase {
  final PinnedEventRepository _repository;
  GetPinnedEventsUseCase(this._repository);

  Future<Either<Failure, List<Event>>> call() => _repository.getPinnedEvents();
}
