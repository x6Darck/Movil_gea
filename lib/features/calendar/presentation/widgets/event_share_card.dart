import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:gea_app/config/theme/app_theme.dart';
import 'package:gea_app/core/utils/image_utils.dart';
import 'package:gea_app/features/calendar/domain/entities/event.dart';

class EventShareCard extends StatelessWidget {
  final Event event;
  final GlobalKey repaintKey;

  const EventShareCard({
    super.key,
    required this.event,
    required this.repaintKey,
  });

  Color get _eventColor {
    if (event.colorHex != null) {
      try {
        return Color(int.parse(event.colorHex!.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }
    return AppTheme.importantColor;
  }

  /// Captures the widget as an image. Call after widget is rendered.
  static Future<ui.Image> capture(GlobalKey key) async {
    final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    return boundary.toImage(pixelRatio: 3.0);
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = ImageUtils.getFullUrl(event.imageUrl);

    return RepaintBoundary(
      key: repaintKey,
      child: SizedBox(
        width: 360,
        height: 360,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: _eventColor),
                      errorWidget: (_, __, ___) => _buildGradientBackground(),
                    )
                  : _buildGradientBackground(),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.school_rounded, color: AppTheme.importantColor, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'GEA · Universidad',
                        style: TextStyle(
                          color: AppTheme.importantColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (event.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _eventColor.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _eventColor.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        event.category!,
                        style: TextStyle(color: _eventColor, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    event.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),
                  _InfoLine(
                    icon: Icons.calendar_today_rounded,
                    text: DateFormat('d MMM yyyy', 'es_ES').format(event.date),
                  ),
                  const SizedBox(height: 4),
                  _InfoLine(
                    icon: Icons.access_time_rounded,
                    text: DateFormat('HH:mm', 'es_ES').format(event.date) +
                        (event.endDate != null
                            ? ' – ${DateFormat('HH:mm', 'es_ES').format(event.endDate!)}'
                            : ''),
                  ),
                  if (event.location != null) ...[
                    const SizedBox(height: 4),
                    _InfoLine(icon: Icons.location_on_outlined, text: event.location!),
                  ],
                  const SizedBox(height: 14),
                  const Text(
                    'Descárgalo en GEA App',
                    style: TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_eventColor, _eventColor.withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 13),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
