import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gea_app/core/error/failures.dart';
import 'package:gea_app/features/calendar/domain/repositories/pinned_event_repository.dart';
import 'package:gea_app/features/calendar/presentation/providers/pinned_events_provider.dart';
import 'package:gea_app/features/calendar/domain/entities/event.dart';
import 'pinned_events_notifier_test.mocks.dart';

@GenerateMocks([PinnedEventRepository])
void main() {
  final testEvent = Event(
    id: '1',
    title: 'Test',
    description: 'Desc',
    date: DateTime(2026, 6, 1, 10, 0),
  );

  group('PinnedEventsNotifier', () {
    late MockPinnedEventRepository mockRepo;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockRepo = MockPinnedEventRepository();
    });

    test('initial state is loading', () {
      when(mockRepo.getPinnedEvents()).thenAnswer((_) async => Right([testEvent]));
      final notifier = PinnedEventsNotifier(mockRepo);
      expect(notifier.debugState.isLoading, isTrue);
    });

    test('after load, pinnedIds contains event id', () async {
      when(mockRepo.getPinnedEvents()).thenAnswer((_) async => Right([testEvent]));
      final notifier = PinnedEventsNotifier(mockRepo);
      await Future.delayed(Duration.zero);
      expect(notifier.debugState.value, contains('1'));
    });

    test('toggle adds id optimistically when not pinned', () async {
      when(mockRepo.getPinnedEvents()).thenAnswer((_) async => Right([]));
      when(mockRepo.pinEvent('1')).thenAnswer((_) async => const Right(unit));
      final notifier = PinnedEventsNotifier(mockRepo);
      await Future.delayed(Duration.zero);
      notifier.toggle('1');
      expect(notifier.debugState.value, contains('1'));
    });

    test('toggle keeps state on backend error (local storage is source of truth)', () async {
      when(mockRepo.getPinnedEvents()).thenAnswer((_) async => Right([]));
      when(mockRepo.pinEvent('1')).thenAnswer(
        (_) async => Left(ServerFailure('Error')),
      );
      final notifier = PinnedEventsNotifier(mockRepo);
      await Future.delayed(Duration.zero);
      await notifier.toggle('1');
      // State is NOT reverted — local SharedPreferences is source of truth.
      expect(notifier.debugState.value, contains('1'));
    });
  });
}
