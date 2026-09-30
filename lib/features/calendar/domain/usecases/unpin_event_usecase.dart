import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../repositories/pinned_event_repository.dart';

class UnpinEventUseCase {
  final PinnedEventRepository _repository;
  UnpinEventUseCase(this._repository);

  Future<Either<Failure, Unit>> call(String eventId) => _repository.unpinEvent(eventId);
}
