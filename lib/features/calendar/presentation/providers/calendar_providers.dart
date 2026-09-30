import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gea_app/core/network/network_providers.dart';
import 'package:gea_app/core/providers/connectivity_providers.dart';
import '../../data/repositories/event_repository_impl.dart';
import '../../domain/repositories/event_repository.dart';
import '../../domain/entities/event.dart';

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  final dio = ref.watch(dioClientProvider).dio;
  final cache = ref.watch(offlineCacheServiceProvider);
  return EventRepositoryImpl(dio, cache);
});

final eventsProvider = FutureProvider<List<Event>>((ref) async {
  final repository = ref.watch(eventRepositoryProvider);
  final result = await repository.getEvents();
  return result.fold(
    (failure) => throw failure.message,
    (events) => events,
  );
});

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final filteredEventsProvider = Provider<List<Event>>((ref) {
  final eventsAsync = ref.watch(eventsProvider);
  final selectedDate = ref.watch(selectedDateProvider);

  return eventsAsync.when(
    data: (events) {
      final filtered = events
          .where((e) =>
              e.date.year == selectedDate.year &&
              e.date.month == selectedDate.month &&
              e.date.day == selectedDate.day)
          .toList();

      filtered.sort((a, b) {
        if (a.isImportant && !b.isImportant) return -1;
        if (!a.isImportant && b.isImportant) return 1;
        return a.date.compareTo(b.date);
      });

      return filtered;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
