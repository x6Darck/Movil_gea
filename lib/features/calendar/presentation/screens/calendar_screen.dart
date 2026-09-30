import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gea_app/l10n/app_localizations.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/calendar_providers.dart';
import '../providers/pinned_events_provider.dart';
import '../../domain/entities/event.dart';

import '../widgets/event_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:gea_app/core/presentation/widgets/gea_empty_state.dart';
import 'package:gea_app/core/presentation/widgets/notification_bell.dart';
import 'package:gea_app/core/utils/image_utils.dart';
import 'package:gea_app/config/theme/app_tokens.dart';
import 'package:gea_app/core/presentation/widgets/offline_banner.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  late PageController _pageController;
  int _carouselIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _getFormattedDate(DateTime date, String locale) {
    final dateStr = DateFormat('EEEE, d MMMM', locale).format(date);
    return dateStr.substring(0, 1).toUpperCase() + dateStr.substring(1);
  }

  Widget _buildPlaceholderGraphic(Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.45),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 10,
            bottom: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons.calendar_month_rounded,
              color: color.withValues(alpha: 0.35),
              size: 44,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard(BuildContext context, Event event, ThemeData theme) {
    const goldColor = AppTokens.important;
    final formattedDate = _getFormattedDate(event.date, Localizations.localeOf(context).toString());
    final imageUrl = ImageUtils.getFullUrl(event.imageUrl);
    
    Color categoryColor = theme.colorScheme.primary;
    if (event.colorHex != null) {
      try {
        final hexStr = event.colorHex!.replaceAll('#', '');
        categoryColor = Color(int.parse('FF$hexStr', radix: 16));
      } catch (e) {
        // ignore
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E1B4B),
            Color(0xFF312E81),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: goldColor.withValues(alpha: 0.7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: goldColor.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // 1. Capa de Imagen difuminada en la mitad derecha
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              left: MediaQuery.of(context).size.width * 0.38, // Comienza un poco antes de la mitad
              child: ShaderMask(
                shaderCallback: (rect) {
                  return const LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
                },
                blendMode: BlendMode.dstIn,
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: AppTokens.surface2),
                        errorWidget: (_, __, ___) => _buildPlaceholderGraphic(categoryColor),
                      )
                    : _buildPlaceholderGraphic(categoryColor),
              ),
            ),
            // 2. Capa Interactiva de InkWell y Textos
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => EventCard.showDetails(context, event),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 65, // 65% del ancho para textos
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: goldColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: goldColor.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.star_rounded, color: goldColor, size: 12),
                                      const SizedBox(width: 4),
                                      Text(
                                        AppLocalizations.of(context)!.featured,
                                        style: const TextStyle(
                                          color: goldColor,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: categoryColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    event.category ?? 'General',
                                    style: TextStyle(
                                      color: categoryColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              event.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined, color: Colors.white70, size: 13),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    formattedDate,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.access_time_outlined, color: Colors.white70, size: 13),
                                const SizedBox(width: 6),
                                Text(
                                  event.endDate != null
                                      ? '${DateFormat('h:mm a', 'es_ES').format(event.date)} - ${DateFormat('h:mm a', 'es_ES').format(event.endDate!)}'
                                      : DateFormat('h:mm a', 'es_ES').format(event.date),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, color: Colors.white70, size: 13),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    event.locations?.isNotEmpty == true 
                                        ? event.locations!.join(', ')
                                        : (event.location ?? 'No especificado'),
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Spacer(flex: 35), // 35% de espacio libre para la imagen
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedDate = ref.watch(selectedDateProvider);
    final eventsAsync = ref.watch(eventsProvider);
    final filteredEvents = ref.watch(filteredEventsProvider);
    final pinnedIds = ref.watch(pinnedEventsNotifierProvider).value ?? {};
    final theme = Theme.of(context);
    const goldColor = AppTokens.important;

    // Filtrar eventos destacados (importantes) que sean futuros o de hoy
    final featuredEvents = eventsAsync.maybeWhen(
      data: (events) {
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final list = events
            .where((e) => e.isImportant && (e.date.isAfter(todayStart) || isSameDay(e.date, todayStart)))
            .toList();
        // Ordenar por fecha ascendente para mostrar los más próximos primero
        list.sort((a, b) => a.date.compareTo(b.date));
        return list;
      },
      orElse: () => <Event>[],
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Calendario de Eventos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline_rounded),
            tooltip: 'Eventos fijados',
            onPressed: () => context.push('/eventos/fijados'),
          ),
          IconButton(
            icon: Icon(_calendarFormat == CalendarFormat.week
                ? Icons.calendar_view_month_rounded
                : Icons.calendar_view_week_rounded),
            tooltip: _calendarFormat == CalendarFormat.week
                ? 'Ver mes completo'
                : 'Ver semana',
            onPressed: () {
              setState(() {
                _calendarFormat = _calendarFormat == CalendarFormat.week
                    ? CalendarFormat.month
                    : CalendarFormat.week;
              });
            },
          ),
          const NotificationBell(),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          TweenAnimationBuilder(
            duration: const Duration(milliseconds: 400),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, double value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 10 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TableCalendar(
                locale: 'es_ES',
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: selectedDate,
                calendarFormat: _calendarFormat,
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                rowHeight: 52,
                daysOfWeekHeight: 26,
                selectedDayPredicate: (day) => isSameDay(selectedDate, day),
                onDaySelected: (selectedDay, focusedDay) {
                  ref.read(selectedDateProvider.notifier).state = selectedDay;
                },
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(color: AppTokens.textSecondary, fontWeight: FontWeight.bold, fontSize: 12),
                  weekendStyle: TextStyle(color: AppTokens.primary, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                calendarStyle: CalendarStyle(
                  defaultTextStyle: const TextStyle(color: AppTokens.textPrimary, fontWeight: FontWeight.w500, fontSize: 15),
                  weekendTextStyle: const TextStyle(color: AppTokens.primary, fontWeight: FontWeight.w500, fontSize: 15),
                  outsideTextStyle: const TextStyle(color: AppTokens.textMuted),
                  outsideDaysVisible: false,
                  selectedDecoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  todayDecoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.primary, width: 2),
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  todayTextStyle: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  defaultDecoration: const BoxDecoration(
                    shape: BoxShape.rectangle,
                  ),
                  weekendDecoration: const BoxDecoration(
                    shape: BoxShape.rectangle,
                  ),
                  markerDecoration: const BoxDecoration(color: AppTokens.primary, shape: BoxShape.circle),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    // All events for this day
                    final dayEvents = eventsAsync.value?.where((e) =>
                      e.date.year == date.year &&
                      e.date.month == date.month &&
                      e.date.day == date.day
                    ).toList() ?? [];

                    if (dayEvents.isEmpty) return null;

                    // Check if any of this day's events are pinned
                    final hasPinned = dayEvents.any((e) => pinnedIds.contains(e.id));

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: dayEvents.any((e) => e.isImportant)
                                ? AppTokens.important
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        if (hasPinned)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTokens.important,
                            ),
                          ),
                      ],
                    );
                  },
                  selectedBuilder: (context, date, _) => Container(
                    margin: const EdgeInsets.all(4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      '${date.day}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  todayBuilder: (context, date, _) => Container(
                    margin: const EdgeInsets.all(4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.primary, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${date.day}',
                      style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    color: AppTokens.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                  leftChevronIcon: Icon(Icons.chevron_left, color: AppTokens.textSecondary),
                  rightChevronIcon: Icon(Icons.chevron_right, color: AppTokens.textSecondary),
                  headerPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                eventLoader: (day) {
                  return eventsAsync.maybeWhen(
                    data: (events) => events.where((e) => isSameDay(e.date, day)).toList(),
                    orElse: () => [],
                  );
                },
              ),
            ),
          ),
          
          // Carrusel de Eventos Destacados (Se muestra cuando el calendario está contraído)
          if (_calendarFormat == CalendarFormat.week && featuredEvents.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: goldColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.featuredEvents,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: goldColor,
                      letterSpacing: 0.8,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 170,
              child: PageView.builder(
                controller: _pageController,
                itemCount: featuredEvents.length,
                onPageChanged: (index) {
                  setState(() {
                    _carouselIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildFeaturedCard(context, featuredEvents[index], theme);
                },
              ),
            ),
            if (featuredEvents.length > 1) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(featuredEvents.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _carouselIndex == index ? 14 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _carouselIndex == index ? goldColor : theme.dividerColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ],
            const SizedBox(height: 8),
          ],

          Divider(height: 1, color: theme.dividerColor),
          const SizedBox(height: 8),
          if (!eventsAsync.isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Eventos para el ${DateFormat('dd MMMM', 'es_ES').format(selectedDate)}',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(eventsProvider);
                await ref.read(eventsProvider.future);
              },
              child: eventsAsync.isLoading
                  ? Skeletonizer(
                      enabled: true,
                      child: ListView.builder(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: 5,
                        itemBuilder: (_, __) => const _EventCardSkeleton(),
                      ),
                    )
                  : filteredEvents.isEmpty
                      ? ListView(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 48),
                            Center(
                              child: GeaEmptyState(
                                icon: Icons.event_busy_outlined,
                                title: l10n.noEvents,
                                description: l10n.noEventsDesc,
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(
                              left: 16, right: 16, bottom: 100),
                          itemCount: filteredEvents.length,
                          itemBuilder: (context, index) {
                            final event = filteredEvents[index];
                            return TweenAnimationBuilder(
                              key: ValueKey(event.id),
                              duration: Duration(
                                  milliseconds: 300 + (index * 50)),
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
                              child: EventCard(event: event),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCardSkeleton extends StatelessWidget {
  const _EventCardSkeleton();

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
                borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
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
                          Container(height: 14, color: AppTokens.surface3),
                          const SizedBox(height: 8),
                          Container(height: 11, color: AppTokens.surface3, width: 120),
                          const SizedBox(height: 4),
                          Container(height: 11, color: AppTokens.surface3, width: 160),
                          const SizedBox(height: 8),
                          Container(height: 11, color: AppTokens.surface3, width: 80),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTokens.surface3,
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
