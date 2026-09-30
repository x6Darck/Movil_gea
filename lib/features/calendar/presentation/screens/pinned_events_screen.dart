import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:gea_app/core/presentation/widgets/gea_empty_state.dart';
import 'package:gea_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:gea_app/features/calendar/presentation/providers/calendar_providers.dart';
import 'package:gea_app/features/calendar/presentation/providers/pinned_events_provider.dart';
import 'package:gea_app/features/calendar/presentation/widgets/event_card.dart';

class PinnedEventsScreen extends ConsumerWidget {
  const PinnedEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos Fijados'),
        centerTitle: true,
        elevation: 0,
      ),
      body: authState.user == null
          ? _buildGuestView(context, theme)
          : _buildPinnedList(context, ref),
    );
  }

  Widget _buildGuestView(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_outline_rounded, size: 72, color: theme.colorScheme.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 24),
            Text(
              'Inicia sesión para fijar eventos',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Guarda tus eventos favoritos y accede a ellos rápidamente desde aquí.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinnedList(BuildContext context, WidgetRef ref) {
    final pinnedState = ref.watch(pinnedEventsNotifierProvider);
    final eventsAsync = ref.watch(eventsProvider);

    return pinnedState.when(
      loading: () => Skeletonizer(
        enabled: true,
        child: ListView.builder(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
          itemCount: 5,
          itemBuilder: (_, __) => const _PinnedCardSkeleton(),
        ),
      ),
      error: (_, __) => GeaEmptyState(
        icon: Icons.error_outline,
        title: 'Error al cargar',
        description: 'No se pudieron obtener tus eventos fijados. Verifica tu conexión.',
        actionText: 'Reintentar',
        onAction: () => ref.invalidate(pinnedEventsNotifierProvider),
      ),
      data: (pinnedIds) {
        if (pinnedIds.isEmpty) {
          return const GeaEmptyState(
            icon: Icons.bookmark_outline_rounded,
            title: 'Sin eventos fijados',
            description: 'Toca el ícono de marcador en cualquier evento para guardarlo aquí.',
          );
        }

        return eventsAsync.when(
          loading: () => Skeletonizer(
            enabled: true,
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
              itemCount: pinnedIds.length,
              itemBuilder: (_, __) => const _PinnedCardSkeleton(),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (events) {
            final pinned = events
                .where((e) => pinnedIds.contains(e.id))
                .toList()
              ..sort((a, b) => a.date.compareTo(b.date));

            return ListView.builder(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
              itemCount: pinned.length,
              itemBuilder: (context, i) => EventCard(event: pinned[i]),
            );
          },
        );
      },
    );
  }
}

class _PinnedCardSkeleton extends StatelessWidget {
  const _PinnedCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 88,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
