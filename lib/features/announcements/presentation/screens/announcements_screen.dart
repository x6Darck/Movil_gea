import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:gea_app/l10n/app_localizations.dart';
import '../providers/announcement_providers.dart';
import '../widgets/announcement_card.dart';
import 'package:gea_app/config/theme/app_tokens.dart';
import 'package:gea_app/core/presentation/widgets/gea_empty_state.dart';
import 'package:gea_app/core/presentation/widgets/notification_bell.dart';
import 'package:gea_app/core/presentation/widgets/offline_banner.dart';

class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final announcementsAsync = ref.watch(announcementsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.announcementsTitle),
        actions: const [NotificationBell()],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: announcementsAsync.when(
        loading: () => Skeletonizer(
          enabled: true,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: 6,
            itemBuilder: (_, __) => const _AnnouncementCardSkeleton(),
          ),
        ),
        error: (_, __) => Center(
          child: GeaEmptyState(
            icon: Icons.error_outline_rounded,
            title: l10n.errorTitle,
            description: l10n.announcementsError,
            actionText: l10n.retry,
            onAction: () => ref.invalidate(announcementsProvider),
          ),
        ),
        data: (announcements) {
          if (announcements.isEmpty) {
            return Center(
              child: GeaEmptyState(
                icon: Icons.campaign_outlined,
                title: l10n.noAnnouncements,
                description: l10n.noAnnouncementsDesc,
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(announcementsProvider);
              await ref.read(announcementsProvider.future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
              itemCount: announcements.length,
              itemBuilder: (context, index) {
                final announcement = announcements[index];
                return TweenAnimationBuilder(
                  key: ValueKey(announcement.id),
                  duration: Duration(milliseconds: 300 + (index * 50)),
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, double value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: AnnouncementCard(announcement: announcement),
                );
              },
            ),
          );
        },
      ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementCardSkeleton extends StatelessWidget {
  const _AnnouncementCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTokens.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTokens.surface3),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: const BoxDecoration(
                color: AppTokens.textMuted,
                borderRadius:
                    BorderRadius.horizontal(left: Radius.circular(12)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(height: 14, color: AppTokens.textMuted),
                          const SizedBox(height: 6),
                          Container(
                              height: 12, color: AppTokens.textMuted, width: 200),
                          const SizedBox(height: 6),
                          Container(
                              height: 12, color: AppTokens.textMuted, width: 220),
                          const SizedBox(height: 8),
                          Container(
                              height: 11, color: AppTokens.textMuted, width: 160),
                          const SizedBox(height: 4),
                          Container(
                              height: 11, color: AppTokens.textMuted, width: 100),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTokens.textMuted,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
