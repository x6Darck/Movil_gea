import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gea_app/core/presentation/widgets/gea_empty_state.dart';
import '../providers/announcement_providers.dart';
import '../widgets/my_request_card.dart';

class MyRequestsScreen extends ConsumerWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final requestsAsync = ref.watch(myRequestsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Mis Solicitudes'),
        centerTitle: true,
        elevation: 0,
      ),
      body: requestsAsync.when(
        data: (requests) {
          if (requests.isEmpty) {
            return const Center(
              child: GeaEmptyState(
                icon: Icons.inbox_outlined,
                title: 'Aún no has enviado solicitudes',
                description: 'Cuando solicites un anuncio, aquí verás su estado.',
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(myRequestsProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final r = requests[index];
                return MyRequestCard(
                  request: r,
                  onEdit: r.status.isEditable
                      ? () async {
                          await context.push('/request-announcement', extra: r);
                          ref.invalidate(myRequestsProvider);
                        }
                      : null,
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: GeaEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'No se pudieron cargar tus solicitudes',
            description: 'Ocurrió un error de conexión. Intenta de nuevo.',
            actionText: 'Reintentar',
            onAction: () => ref.invalidate(myRequestsProvider),
          ),
        ),
      ),
    );
  }
}
