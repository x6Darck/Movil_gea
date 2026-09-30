import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import 'package:gea_app/features/calendar/domain/entities/event.dart';
import 'package:gea_app/features/calendar/presentation/widgets/event_share_card.dart';

class ShareEventBottomSheet extends StatefulWidget {
  final Event event;

  const ShareEventBottomSheet({super.key, required this.event});

  static void show(BuildContext context, Event event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ShareEventBottomSheet(event: event),
    );
  }

  @override
  State<ShareEventBottomSheet> createState() => _ShareEventBottomSheetState();
}

class _ShareEventBottomSheetState extends State<ShareEventBottomSheet> {
  final GlobalKey _repaintKey = GlobalKey();
  bool _isSharingImage = false;
  bool _isCopyingLink = false;

  Future<void> _shareAsImage() async {
    if (_isSharingImage) return;
    setState(() => _isSharingImage = true);

    try {
      // Allow the Offstage widget to render before capturing
      await Future.delayed(const Duration(milliseconds: 200));

      final ui.Image image = await EventShareCard.capture(_repaintKey);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) throw Exception('No se pudo generar la imagen');

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/evento_${widget.event.id}_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '¡Mira este evento de GEA!\n${widget.event.title}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al compartir imagen: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharingImage = false);
    }
  }

  Future<void> _copyLink() async {
    if (_isCopyingLink) return;
    final link = widget.event.link;
    if (link == null || link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este evento no tiene enlace disponible')),
      );
      return;
    }

    setState(() => _isCopyingLink = true);
    try {
      await Clipboard.setData(ClipboardData(text: link));
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enlace copiado al portapapeles')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCopyingLink = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Compartir evento',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 24),

          // Off-screen card for image capture.
          // ClipRect clips visual output to 0×0 so nothing is visible, but
          // still calls paint() on its children — so RepaintBoundary is marked
          // as painted and toImage() works. Offstage skips paint entirely.
          ClipRect(
            child: SizedBox(
              width: 0,
              height: 0,
              child: OverflowBox(
                maxWidth: 360,
                maxHeight: 360,
                child: EventShareCard(
                  event: widget.event,
                  repaintKey: _repaintKey,
                ),
              ),
            ),
          ),

          // Share options
          _ShareOption(
            icon: Icons.image_outlined,
            label: 'Compartir como imagen',
            subtitle: 'Genera una tarjeta visual del evento',
            isLoading: _isSharingImage,
            onTap: _shareAsImage,
          ),
          const SizedBox(height: 12),
          _ShareOption(
            icon: Icons.link_rounded,
            label: 'Copiar enlace',
            subtitle: widget.event.link != null
                ? 'Copia el enlace del evento al portapapeles'
                : 'Este evento no tiene enlace',
            isLoading: _isCopyingLink,
            enabled: widget.event.link != null,
            onTap: _copyLink,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isLoading;
  final bool enabled;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.isLoading = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor =
        enabled ? theme.colorScheme.onSurface : theme.disabledColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled && !isLoading ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: effectiveColor, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 15,
                        color: effectiveColor,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: enabled ? theme.colorScheme.secondary : theme.disabledColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
