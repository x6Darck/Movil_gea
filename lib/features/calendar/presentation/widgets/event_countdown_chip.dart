import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gea_app/config/theme/app_tokens.dart';
import 'package:intl/intl.dart';

class EventCountdownChip extends StatefulWidget {
  final DateTime date;
  final DateTime? endDate;

  const EventCountdownChip({
    super.key,
    required this.date,
    this.endDate,
  });

  /// Lógica pura extraída para testabilidad.
  static String? computeLabel({
    required DateTime date,
    required DateTime? endDate,
    required DateTime now,
  }) {
    final effectiveEnd = endDate ?? date.add(const Duration(hours: 1));

    // Evento en curso
    if (now.isAfter(date) && now.isBefore(effectiveEnd)) {
      return 'En curso';
    }

    // Evento ya terminó
    if (now.isAfter(effectiveEnd)) return null;

    // Más de 7 días → no mostrar
    final diff = date.difference(now);
    if (diff.inDays > 7) return null;

    // Hoy
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      if (hours > 0) return 'Hoy · en ${hours}h ${minutes}min';
      return 'Hoy · en ${minutes}min';
    }

    // Mañana
    final tomorrow = now.add(const Duration(days: 1));
    if (date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day) {
      return 'Mañana · ${DateFormat('HH:mm').format(date)}';
    }

    // 2-7 días
    return diff.inDays == 1 ? 'Faltan 1 día' : 'Faltan ${diff.inDays} días';
  }

  @override
  State<EventCountdownChip> createState() => _EventCountdownChipState();
}

class _EventCountdownChipState extends State<EventCountdownChip> {
  late Timer _timer;
  String? _label;

  @override
  void initState() {
    super.initState();
    _updateLabel();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _updateLabel());
  }

  @override
  void didUpdateWidget(EventCountdownChip old) {
    super.didUpdateWidget(old);
    if (old.date != widget.date || old.endDate != widget.endDate) {
      _updateLabel();
    }
  }

  void _updateLabel() {
    final label = EventCountdownChip.computeLabel(
      date: widget.date,
      endDate: widget.endDate,
      now: DateTime.now(),
    );
    if (mounted) setState(() => _label = label);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_label == null) return const SizedBox.shrink();

    final isLive = _label == 'En curso';
    final color = isLive ? AppTokens.success : Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLive ? Icons.radio_button_checked : Icons.schedule_rounded,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            _label!,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
