import 'package:flutter/material.dart';
import 'package:gea_app/config/theme/app_tokens.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gea_app/features/calendar/domain/entities/event.dart';

class StreamBadge extends StatelessWidget {
  final Event event;

  const StreamBadge({super.key, required this.event});

  bool get _isLive {
    if (event.endDate == null) return false;
    final now = DateTime.now();
    return now.isAfter(event.date) && now.isBefore(event.endDate!);
  }

  Future<void> _openLink() async {
    if (event.link == null) return;
    final uri = Uri.tryParse(event.link!);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (event.link == null) return const SizedBox.shrink();

    final isLive = _isLive;
    final color = isLive ? AppTokens.error : Colors.deepPurple;
    final label = isLive ? 'EN VIVO' : 'STREAM';

    return GestureDetector(
      onTap: _openLink,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PulsingDot(color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
