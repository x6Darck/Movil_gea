import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../repositories/pinned_event_repository.dart';

class PinEventUseCase {
  final PinnedEventRepository _repository;
  PinEventUseCase(this._repository);

  Future<Either<Failure, Unit>> call(String eventId) => _repository.pinEvent(eventId);
}
