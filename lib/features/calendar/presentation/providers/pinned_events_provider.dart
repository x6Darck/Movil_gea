import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gea_app/core/network/network_providers.dart';
import '../../data/datasources/pinned_event_remote_datasource.dart';
import '../../data/repositories/pinned_event_repository_impl.dart';
import '../../domain/repositories/pinned_event_repository.dart';

final pinnedEventRepositoryProvider = Provider<PinnedEventRepository>((ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return PinnedEventRepositoryImpl(PinnedEventRemoteDatasource(dio));
});

final pinnedEventsNotifierProvider =
    StateNotifierProvider<PinnedEventsNotifier, AsyncValue<Set<String>>>((ref) {
  final repo = ref.watch(pinnedEventRepositoryProvider);
  return PinnedEventsNotifier(repo);
});

class PinnedEventsNotifier extends StateNotifier<AsyncValue<Set<String>>> {
  final PinnedEventRepository _repository;
  static const _prefsKey = 'pinned_event_ids';

  PinnedEventsNotifier(this._repository) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    final result = await _repository.getPinnedEvents();
    await result.fold(
      (_) async {
        // Backend unavailable — fall back to local storage so the feature
        // works even before the endpoint is implemented on the server.
        final prefs = await SharedPreferences.getInstance();
        final localIds = prefs.getStringList(_prefsKey) ?? [];
        state = AsyncValue.data(localIds.toSet());
      },
      (events) async {
        final ids = events.map((e) => e.id).toSet();
        // Keep local cache in sync with backend truth.
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_prefsKey, ids.toList());
        state = AsyncValue.data(ids);
      },
    );
  }

  Future<void> toggle(String eventId) async {
    final current = state.value ?? {};
    final isPinned = current.contains(eventId);

    // Optimistic update
    final updated = Set<String>.from(current);
    if (isPinned) {
      updated.remove(eventId);
    } else {
      updated.add(eventId);
    }
    state = AsyncValue.data(updated);

    // Persist locally — source of truth while backend is unavailable.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, updated.toList());

    // Backend sync (best effort, silent — local storage already persisted).
    if (isPinned) {
      await _repository.unpinEvent(eventId);
    } else {
      await _repository.pinEvent(eventId);
    }
  }

  bool isPinned(String eventId) => state.value?.contains(eventId) ?? false;
}
