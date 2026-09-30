import 'package:flutter/material.dart';
import 'package:gea_app/config/theme/app_tokens.dart';

class ImportantEventPulse extends StatefulWidget {
  const ImportantEventPulse({super.key});

  @override
  State<ImportantEventPulse> createState() => _ImportantEventPulseState();
}

class _ImportantEventPulseState extends State<ImportantEventPulse> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // Slower, more elegant pulse
    )..repeat(reverse: true);
    
    // More subtle pulsing
    _animation = Tween<double>(begin: 0.8, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const goldColor = AppTokens.important;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.all(2), // Closer to the container
          decoration: BoxDecoration(
            border: Border.all(
              color: goldColor.withAlpha((255 * (0.4 + (_animation.value / 10))).toInt()), // Subtle border
              width: 1.5 + (_animation.value / 4), // Thinner
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: goldColor.withAlpha((60 * (_animation.value / 4)).toInt()), // Much more transparent shadow
                blurRadius: _animation.value * 2,
                spreadRadius: _animation.value / 2,
              ),
            ],
          ),
        );
      },
    );
  }
}
