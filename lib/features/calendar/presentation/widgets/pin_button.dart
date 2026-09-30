import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/pinned_events_provider.dart';

class PinButton extends ConsumerWidget {
  final String eventId;
  final bool isAuthenticated;
  final double size;

  const PinButton({
    super.key,
    required this.eventId,
    required this.isAuthenticated,
    this.size = 22,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinnedState = ref.watch(pinnedEventsNotifierProvider);
    final isPinned = pinnedState.value?.contains(eventId) ?? false;

    return GestureDetector(
      onTap: () => _onTap(context, ref, isPinned),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: isPinned ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        builder: (_, t, __) => Icon(
          isPinned ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
          size: size,
          color: Color.lerp(
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            Theme.of(context).colorScheme.primary,
            t,
          ),
        ),
      ),
    );
  }

  Future<void> _onTap(BuildContext context, WidgetRef ref, bool isPinned) async {
    if (!isAuthenticated) {
      _showLoginPrompt(context);
      return;
    }

    await ref.read(pinnedEventsNotifierProvider.notifier).toggle(eventId);
  }

  void _showLoginPrompt(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bookmark_outline_rounded, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Inicia sesión para fijar eventos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Guarda tus eventos favoritos y accede a ellos rápidamente.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/login');
                },
                child: const Text('Iniciar sesión'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
