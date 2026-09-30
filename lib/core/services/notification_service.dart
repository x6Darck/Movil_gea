import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gea_app/config/router/app_router.dart';
import 'package:gea_app/features/calendar/domain/entities/event.dart';
import 'package:gea_app/features/calendar/data/models/event_model.dart';
import 'package:gea_app/features/calendar/presentation/widgets/event_card.dart';
import 'package:gea_app/config/theme/app_theme.dart';
import 'package:intl/intl.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Timer? _pollingTimer;
  final Set<String> _notifiedEventIds = {};
  bool _isInitialized = false;

  // En producción, aquí se usaría FirebaseMessaging.instance
  final bool useFirebase = false;

  static final Random _random = Random();

  /// Duración hasta el próximo sondeo: 70-110s con jitter aleatorio.
  ///
  /// Un intervalo fijo de 15s multiplicado por miles de dispositivos genera
  /// tráfico de fondo constante y sincronizado contra el backend. El jitter
  /// evita que todas las apps golpeen el servidor en el mismo instante.
  static Duration computePollingDelay() {
    const baseMs = 70000;
    const jitterRangeMs = 40000; // reparte el próximo check entre 70s y 110s
    return Duration(milliseconds: baseMs + _random.nextInt(jitterRangeMs));
  }

  /// Si hay un sondeo programado activo (no confundir con "app en foreground").
  bool get isPolling => _pollingTimer != null && _pollingTimer!.isActive;

  /// Inicializa el servicio de notificaciones y comienza el sondeo
  void init(Dio dio) {
    if (_isInitialized) return;
    _isInitialized = true;

    // Registrar el dispositivo en el backend si el usuario ya está logueado
    registerDevice(dio);

    _scheduleNextCheck(dio);

    // Primera comprobación inmediata
    _checkForImportantEvents(dio);
  }

  void _scheduleNextCheck(Dio dio) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer(computePollingDelay(), () {
      _checkForImportantEvents(dio);
      _scheduleNextCheck(dio);
    });
  }

  /// Detiene el sondeo. Se llama cuando la app pasa a segundo plano
  /// (`AppLifecycleState` distinto de `resumed`) para no generar tráfico
  /// mientras el usuario no está usando la app.
  void pausePolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Reanuda el sondeo. Se llama cuando la app vuelve a primer plano.
  /// Sin efecto si ya hay un sondeo activo.
  void resumePolling(Dio dio) {
    if (isPolling) return;
    _scheduleNextCheck(dio);
  }

  /// Cancela el polling cuando la app se cierra
  void dispose() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isInitialized = false;
  }

  /// Registra el token (simulado o FCM real) en el backend si hay sesión activa
  Future<void> registerDevice(Dio dio) async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'jwt_token');
      if (token == null) {
        debugPrint("📢 Omitiendo registro de dispositivo: No hay sesión activa (JWT no encontrado).");
        return;
      }

      // Token único simulado por dispositivo o token real de FCM en el futuro
      const String deviceToken = "FCM_GEA_APP_MOBILE_TOKEN_SIMULATED_PRO_9988";
      
      await dio.post('/usuario/dispositivos/registrar', data: {
        'token': deviceToken,
      });
      debugPrint("📢 Dispositivo registrado en el servidor de notificaciones.");
    } catch (e) {
      debugPrint("❌ Error al registrar dispositivo para notificaciones: $e");
    }
  }

  /// Desregistra el token del backend al cerrar sesión
  Future<void> unregisterDevice(Dio dio) async {
    try {
      const String deviceToken = "FCM_GEA_APP_MOBILE_TOKEN_SIMULATED_PRO_9988";
      await dio.post('/usuario/dispositivos/desregistrar', data: {
        'token': deviceToken,
      });
      debugPrint("📢 Dispositivo desregistrado del servidor de notificaciones.");
    } catch (e) {
      debugPrint("❌ Error al desregistrar dispositivo: $e");
    }
  }

  /// Consulta los eventos publicados y detecta si hay alguno nuevo marcado como importante
  Future<void> _checkForImportantEvents(Dio dio) async {
    try {
      final response = await dio.get('/app/eventos/publicados');
      final List<dynamic> data = response.data['data'] ?? response.data;
      
      // Mapear los eventos utilizando el modelo robusto de la aplicación
      final List<Event> events = data
          .map((json) => EventModel.fromJson(json as Map<String, dynamic>))
          .toList();

      for (final event in events) {
        if (event.isImportant) {
          // Si es importante y aún no lo hemos notificado en esta sesión
          if (!_notifiedEventIds.contains(event.id)) {
            _notifiedEventIds.add(event.id);
            _showInAppNotification(event);
          }
        }
      }
    } catch (e) {
      debugPrint("❌ Error al comprobar eventos importantes: $e");
    }
  }

  /// Muestra el banner flotante in-app interactivo y llamativo
  void _showInAppNotification(Event event) {
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _InAppNotificationBanner(
        event: event,
        onDismiss: () {
          entry.remove();
        },
      ),
    );

    overlay.insert(entry);
  }
}

class _InAppNotificationBanner extends StatefulWidget {
  final Event event;
  final VoidCallback onDismiss;

  const _InAppNotificationBanner({
    required this.event,
    required this.onDismiss,
  });

  @override
  State<_InAppNotificationBanner> createState() => _InAppNotificationBannerState();
}

class _InAppNotificationBannerState extends State<_InAppNotificationBanner> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isVisible = false;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Animar la entrada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isVisible = true;
      });
    });

    // Auto ocultar después de 6 segundos
    _autoDismissTimer = Timer(const Duration(seconds: 6), () {
      _dismiss();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  void _dismiss() {
    if (!mounted) return;
    setState(() {
      _isVisible = false;
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    const goldColor = AppTheme.importantColor;
    
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
      top: _isVisible ? mediaQuery.padding.top + 12 : -150,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () {
            _dismiss();
            EventCard.showDetails(context, widget.event);
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1E1B4B).withValues(alpha: 0.95), // Azul oscuro profundo
                  const Color(0xFF111827).withValues(alpha: 0.95), // Gris casi negro
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: goldColor.withValues(alpha: 0.8), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: goldColor.withValues(alpha: 0.25),
                  blurRadius: 16,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Efecto de barra de progreso que se agota
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 3,
                      alignment: Alignment.centerLeft,
                      color: Colors.white10,
                      child: AnimatedContainer(
                        duration: const Duration(seconds: 6),
                        width: _isVisible ? mediaQuery.size.width - 32 : 0,
                        color: goldColor,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Icono vibrante con animación de pulso
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Color(0x20F59E0B),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.star_rounded,
                              color: AppTheme.importantColor,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Contenido de la notificación
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: goldColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      "IMPORTANTE",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Nuevo evento publicado",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.event.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, color: Colors.white54, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('h:mm a', 'es_ES').format(widget.event.date),
                                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.location_on_outlined, color: Colors.white54, size: 12),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      widget.event.location ?? 'Por definir',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Botón de cerrar
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                          onPressed: _dismiss,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
