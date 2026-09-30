# Event Engagement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Añadir interacción pasiva (countdown, badges) y activa (pin de eventos + compartir como imagen) a la app GEA.

**Architecture:** Clean Architecture por capas (domain/data/presentation) en `lib/features/calendar/`. Los eventos fijados usan un `StateNotifier` con actualización optimista + sync backend. El share card se genera off-screen con `RepaintBoundary`. Las mejoras pasivas son widgets stateful independientes.

**Tech Stack:** Flutter, Riverpod (StateNotifierProvider, FutureProvider), Dio, fpdart Either, share_plus, url_launcher, RepaintBoundary

---

## Mapa de archivos

**Nuevos:**
- `lib/features/calendar/presentation/widgets/event_countdown_chip.dart`
- `lib/features/calendar/presentation/widgets/stream_badge.dart`
- `lib/features/calendar/domain/repositories/pinned_event_repository.dart`
- `lib/features/calendar/domain/usecases/pin_event_usecase.dart`
- `lib/features/calendar/domain/usecases/unpin_event_usecase.dart`
- `lib/features/calendar/domain/usecases/get_pinned_events_usecase.dart`
- `lib/features/calendar/data/datasources/pinned_event_remote_datasource.dart`
- `lib/features/calendar/data/repositories/pinned_event_repository_impl.dart`
- `lib/features/calendar/presentation/providers/pinned_events_provider.dart`
- `lib/features/calendar/presentation/widgets/pin_button.dart`
- `lib/features/calendar/presentation/screens/pinned_events_screen.dart`
- `lib/features/calendar/presentation/widgets/event_share_card.dart`
- `lib/features/calendar/presentation/widgets/share_event_bottom_sheet.dart`
- `test/features/calendar/event_countdown_chip_test.dart`
- `test/features/calendar/pinned_event_repository_test.dart`
- `test/features/calendar/pinned_events_notifier_test.dart`

**Modificados:**
- `pubspec.yaml` — añadir share_plus, url_launcher
- `lib/features/calendar/presentation/widgets/event_card.dart` — ConsumerWidget + chips + pin + share
- `lib/features/calendar/presentation/providers/calendar_providers.dart` — añadir pinnedEventsProvider
- `lib/features/calendar/presentation/screens/calendar_screen.dart` — bookmark AppBar + calendar markers
- `lib/config/router/app_router.dart` — ruta /eventos/fijados

---

## Task 1: Añadir paquetes share_plus y url_launcher

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Añadir dependencias**

En `pubspec.yaml`, dentro de `dependencies:`, añadir después de `cached_network_image`:

```yaml
  share_plus: ^10.0.0
  url_launcher: ^6.3.0
```

- [ ] **Step 2: Obtener dependencias**

```bash
flutter pub get
```

Expected: `Got dependencies!` sin errores.

- [ ] **Step 3: Verificar análisis**

```bash
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add share_plus and url_launcher dependencies"
```

---

## Task 2: EventCountdownChip widget

**Files:**
- Create: `lib/features/calendar/presentation/widgets/event_countdown_chip.dart`
- Create: `test/features/calendar/event_countdown_chip_test.dart`

- [ ] **Step 1: Escribir test fallido**

Crear `test/features/calendar/event_countdown_chip_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gea_app/features/calendar/presentation/widgets/event_countdown_chip.dart';

void main() {
  group('EventCountdownChip label logic', () {
    test('returns "En curso" when now is between date and endDate', () {
      final now = DateTime.now();
      final label = EventCountdownChip.computeLabel(
        date: now.subtract(const Duration(minutes: 30)),
        endDate: now.add(const Duration(minutes: 30)),
        now: now,
      );
      expect(label, 'En curso');
    });

    test('returns null when event has already ended', () {
      final now = DateTime.now();
      final label = EventCountdownChip.computeLabel(
        date: now.subtract(const Duration(hours: 3)),
        endDate: now.subtract(const Duration(hours: 1)),
        now: now,
      );
      expect(label, isNull);
    });

    test('returns "Hoy" label when event is today and has not started', () {
      final now = DateTime.now();
      final label = EventCountdownChip.computeLabel(
        date: now.add(const Duration(hours: 2)),
        endDate: null,
        now: now,
      );
      expect(label, startsWith('Hoy'));
    });

    test('returns "Mañana" label when event is tomorrow', () {
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));
      final eventDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10, 0);
      final label = EventCountdownChip.computeLabel(
        date: eventDate,
        endDate: null,
        now: now,
      );
      expect(label, startsWith('Mañana'));
    });

    test('returns "Faltan X días" when event is more than 1 day away', () {
      final now = DateTime.now();
      final label = EventCountdownChip.computeLabel(
        date: now.add(const Duration(days: 4)),
        endDate: null,
        now: now,
      );
      expect(label, contains('días'));
    });

    test('returns null when event is more than 7 days away', () {
      final now = DateTime.now();
      final label = EventCountdownChip.computeLabel(
        date: now.add(const Duration(days: 10)),
        endDate: null,
        now: now,
      );
      expect(label, isNull);
    });
  });
}
```

- [ ] **Step 2: Verificar que el test falla**

```bash
flutter test test/features/calendar/event_countdown_chip_test.dart
```

Expected: FAIL — `EventCountdownChip` not found.

- [ ] **Step 3: Implementar EventCountdownChip**

Crear `lib/features/calendar/presentation/widgets/event_countdown_chip.dart`:

```dart
import 'dart:async';
import 'package:flutter/material.dart';
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
    return 'Faltan ${diff.inDays} días';
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
    final color = isLive ? Colors.green : Theme.of(context).colorScheme.primary;

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
```

- [ ] **Step 4: Verificar que los tests pasan**

```bash
flutter test test/features/calendar/event_countdown_chip_test.dart
```

Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/calendar/presentation/widgets/event_countdown_chip.dart test/features/calendar/event_countdown_chip_test.dart
git commit -m "feat: add EventCountdownChip widget with testable label logic"
```

---

## Task 3: StreamBadge widget

**Files:**
- Create: `lib/features/calendar/presentation/widgets/stream_badge.dart`

- [ ] **Step 1: Crear StreamBadge**

```dart
import 'package:flutter/material.dart';
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
    final color = isLive ? Colors.red : Colors.deepPurple;
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
```

- [ ] **Step 2: Verificar análisis**

```bash
flutter analyze lib/features/calendar/presentation/widgets/stream_badge.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/calendar/presentation/widgets/stream_badge.dart
git commit -m "feat: add StreamBadge widget with pulse animation and url_launcher"
```

---

## Task 4: Integrar CountdownChip y StreamBadge en EventCard

**Files:**
- Modify: `lib/features/calendar/presentation/widgets/event_card.dart`

El `EventCard` actualmente es un `StatelessWidget`. Lo convertiremos a `ConsumerWidget` en Task 12 (cuando integremos el pin). Por ahora solo añadimos los nuevos widgets visuales.

- [ ] **Step 1: Añadir imports en event_card.dart**

En `lib/features/calendar/presentation/widgets/event_card.dart`, añadir al bloque de imports:

```dart
import 'package:gea_app/features/calendar/presentation/widgets/event_countdown_chip.dart';
import 'package:gea_app/features/calendar/presentation/widgets/stream_badge.dart';
```

- [ ] **Step 2: Añadir CountdownChip en el build del card (lista)**

Dentro del método `build`, en el `Column` de texto del card (después del bloque de hora y ubicación, antes de `if (event.category != null)`), añadir:

```dart
const SizedBox(height: 6),
Row(
  children: [
    EventCountdownChip(date: event.date, endDate: event.endDate),
    if (event.link != null) ...[
      const SizedBox(width: 6),
      StreamBadge(event: event),
    ],
  ],
),
```

- [ ] **Step 3: Añadir StreamBadge en el modal showDetails**

En el método estático `showDetails`, dentro del `ListView`, después de la imagen y antes del título, añadir `StreamBadge` junto al badge de categoría existente:

```dart
Row(
  children: [
    if (event.category != null)
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: eventColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          event.category!,
          style: TextStyle(color: eventColor, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    if (event.link != null) ...[
      const SizedBox(width: 8),
      StreamBadge(event: event),
    ],
    const Spacer(),
    if (event.isImportant)
      const Icon(Icons.star_rounded, color: AppTheme.importantColor),
  ],
),
```

- [ ] **Step 4: Verificar análisis**

```bash
flutter analyze lib/features/calendar/presentation/widgets/event_card.dart
```

Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/features/calendar/presentation/widgets/event_card.dart
git commit -m "feat: add countdown chip and stream badge to EventCard"
```

---

## Task 5: Domain layer — PinnedEventRepository + UseCases

**Files:**
- Create: `lib/features/calendar/domain/repositories/pinned_event_repository.dart`
- Create: `lib/features/calendar/domain/usecases/pin_event_usecase.dart`
- Create: `lib/features/calendar/domain/usecases/unpin_event_usecase.dart`
- Create: `lib/features/calendar/domain/usecases/get_pinned_events_usecase.dart`

- [ ] **Step 1: Crear PinnedEventRepository**

```dart
// lib/features/calendar/domain/repositories/pinned_event_repository.dart
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/event.dart';

abstract class PinnedEventRepository {
  Future<Either<Failure, List<Event>>> getPinnedEvents();
  Future<Either<Failure, Unit>> pinEvent(String eventId);
  Future<Either<Failure, Unit>> unpinEvent(String eventId);
}
```

- [ ] **Step 2: Crear use cases**

```dart
// lib/features/calendar/domain/usecases/get_pinned_events_usecase.dart
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/event.dart';
import '../repositories/pinned_event_repository.dart';

class GetPinnedEventsUseCase {
  final PinnedEventRepository _repository;
  GetPinnedEventsUseCase(this._repository);

  Future<Either<Failure, List<Event>>> call() => _repository.getPinnedEvents();
}
```

```dart
// lib/features/calendar/domain/usecases/pin_event_usecase.dart
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../repositories/pinned_event_repository.dart';

class PinEventUseCase {
  final PinnedEventRepository _repository;
  PinEventUseCase(this._repository);

  Future<Either<Failure, Unit>> call(String eventId) => _repository.pinEvent(eventId);
}
```

```dart
// lib/features/calendar/domain/usecases/unpin_event_usecase.dart
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../repositories/pinned_event_repository.dart';

class UnpinEventUseCase {
  final PinnedEventRepository _repository;
  UnpinEventUseCase(this._repository);

  Future<Either<Failure, Unit>> call(String eventId) => _repository.unpinEvent(eventId);
}
```

- [ ] **Step 3: Verificar análisis**

```bash
flutter analyze lib/features/calendar/domain/
```

Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/features/calendar/domain/repositories/pinned_event_repository.dart lib/features/calendar/domain/usecases/
git commit -m "feat: add PinnedEventRepository interface and use cases"
```

---

## Task 6: Data layer — PinnedEventRemoteDatasource + RepositoryImpl

**Files:**
- Create: `lib/features/calendar/data/datasources/pinned_event_remote_datasource.dart`
- Create: `lib/features/calendar/data/repositories/pinned_event_repository_impl.dart`
- Create: `test/features/calendar/pinned_event_repository_test.dart`

- [ ] **Step 1: Escribir test fallido**

```dart
// test/features/calendar/pinned_event_repository_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:gea_app/features/calendar/data/datasources/pinned_event_remote_datasource.dart';

@GenerateMocks([Dio])
void main() {
  group('PinnedEventRemoteDatasource', () {
    late MockDio mockDio;
    late PinnedEventRemoteDatasource datasource;

    setUp(() {
      mockDio = MockDio();
      datasource = PinnedEventRemoteDatasource(mockDio);
    });

    test('getPinnedEvents returns list on 200', () async {
      when(mockDio.get('/app/eventos/fijados')).thenAnswer(
        (_) async => Response(
          data: {'data': []},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/app/eventos/fijados'),
        ),
      );

      final result = await datasource.getPinnedEvents();
      expect(result, isEmpty);
    });

    test('pinEvent calls POST with correct path', () async {
      when(mockDio.post('/app/eventos/fijados/123')).thenAnswer(
        (_) async => Response(
          data: {},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/app/eventos/fijados/123'),
        ),
      );

      await datasource.pinEvent('123');
      verify(mockDio.post('/app/eventos/fijados/123')).called(1);
    });

    test('unpinEvent calls DELETE with correct path', () async {
      when(mockDio.delete('/app/eventos/fijados/123')).thenAnswer(
        (_) async => Response(
          data: {},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/app/eventos/fijados/123'),
        ),
      );

      await datasource.unpinEvent('123');
      verify(mockDio.delete('/app/eventos/fijados/123')).called(1);
    });
  });
}
```

- [ ] **Step 2: Verificar que el test falla**

```bash
flutter test test/features/calendar/pinned_event_repository_test.dart
```

Expected: FAIL — `PinnedEventRemoteDatasource` not found.

- [ ] **Step 3: Implementar datasource**

```dart
// lib/features/calendar/data/datasources/pinned_event_remote_datasource.dart
import 'package:dio/dio.dart';
import '../models/event_model.dart';
import '../../domain/entities/event.dart';

class PinnedEventRemoteDatasource {
  final Dio _dio;
  PinnedEventRemoteDatasource(this._dio);

  Future<List<Event>> getPinnedEvents() async {
    final response = await _dio.get('/app/eventos/fijados');
    final data = response.data['data'] as List? ?? [];
    return data.map((json) => EventModel.fromJson(json)).toList();
  }

  Future<void> pinEvent(String eventId) async {
    await _dio.post('/app/eventos/fijados/$eventId');
  }

  Future<void> unpinEvent(String eventId) async {
    await _dio.delete('/app/eventos/fijados/$eventId');
  }
}
```

- [ ] **Step 4: Implementar repositorio**

```dart
// lib/features/calendar/data/repositories/pinned_event_repository_impl.dart
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/event.dart';
import '../../domain/repositories/pinned_event_repository.dart';
import '../datasources/pinned_event_remote_datasource.dart';

class PinnedEventRepositoryImpl implements PinnedEventRepository {
  final PinnedEventRemoteDatasource _datasource;
  PinnedEventRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, List<Event>>> getPinnedEvents() async {
    try {
      final events = await _datasource.getPinnedEvents();
      return Right(events);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Error fetching pinned events'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> pinEvent(String eventId) async {
    try {
      await _datasource.pinEvent(eventId);
      return const Right(unit);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Error pinning event'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> unpinEvent(String eventId) async {
    try {
      await _datasource.unpinEvent(eventId);
      return const Right(unit);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Error unpinning event'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
```

- [ ] **Step 5: Añadir mockito a dev_dependencies (si no está)**

En `pubspec.yaml`, en `dev_dependencies:`:

```yaml
  mockito: ^5.4.4
  build_runner: ^2.4.8  # ya existe
```

Luego: `flutter pub get`

- [ ] **Step 6: Generar mocks y correr tests**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter test test/features/calendar/pinned_event_repository_test.dart
```

Expected: All tests PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/calendar/data/ test/features/calendar/pinned_event_repository_test.dart pubspec.yaml pubspec.lock
git commit -m "feat: add PinnedEvent datasource and repository implementation"
```

---

## Task 7: PinnedEventsNotifier + Providers

**Files:**
- Create: `lib/features/calendar/presentation/providers/pinned_events_provider.dart`
- Create: `test/features/calendar/pinned_events_notifier_test.dart`

- [ ] **Step 1: Escribir test fallido**

```dart
// test/features/calendar/pinned_events_notifier_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:gea_app/features/calendar/domain/repositories/pinned_event_repository.dart';
import 'package:gea_app/features/calendar/presentation/providers/pinned_events_provider.dart';
import 'package:gea_app/features/calendar/domain/entities/event.dart';

@GenerateMocks([PinnedEventRepository])
void main() {
  final testEvent = Event(
    id: '1',
    title: 'Test',
    description: 'Desc',
    date: DateTime(2026, 6, 1, 10, 0),
  );

  group('PinnedEventsNotifier', () {
    late MockPinnedEventRepository mockRepo;

    setUp(() {
      mockRepo = MockPinnedEventRepository();
    });

    test('initial state is loading', () {
      when(mockRepo.getPinnedEvents()).thenAnswer((_) async => Right([testEvent]));
      final notifier = PinnedEventsNotifier(mockRepo);
      expect(notifier.debugState.isLoading, isTrue);
    });

    test('after load, pinnedIds contains event id', () async {
      when(mockRepo.getPinnedEvents()).thenAnswer((_) async => Right([testEvent]));
      final notifier = PinnedEventsNotifier(mockRepo);
      await Future.delayed(Duration.zero);
      expect(notifier.debugState.value, contains('1'));
    });

    test('toggle adds id optimistically when not pinned', () async {
      when(mockRepo.getPinnedEvents()).thenAnswer((_) async => Right([]));
      when(mockRepo.pinEvent('1')).thenAnswer((_) async => const Right(unit));
      final notifier = PinnedEventsNotifier(mockRepo);
      await Future.delayed(Duration.zero);
      notifier.toggle('1');
      expect(notifier.debugState.value, contains('1'));
    });

    test('toggle reverts on backend error', () async {
      when(mockRepo.getPinnedEvents()).thenAnswer((_) async => Right([]));
      when(mockRepo.pinEvent('1')).thenAnswer(
        (_) async => Left(ServerFailure('Error')),  // import 'package:gea_app/core/error/failures.dart';
      );
      final notifier = PinnedEventsNotifier(mockRepo);
      await Future.delayed(Duration.zero);
      await notifier.toggle('1');
      expect(notifier.debugState.value, isNot(contains('1')));
    });
  });
}
```

- [ ] **Step 2: Verificar que el test falla**

```bash
flutter test test/features/calendar/pinned_events_notifier_test.dart
```

Expected: FAIL — `PinnedEventsNotifier` not found.

- [ ] **Step 3: Implementar PinnedEventsNotifier y providers**

```dart
// lib/features/calendar/presentation/providers/pinned_events_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gea_app/core/network/network_providers.dart';
import '../../data/datasources/pinned_event_remote_datasource.dart';
import '../../data/repositories/pinned_event_repository_impl.dart';
import '../../domain/repositories/pinned_event_repository.dart';

final pinnedEventRepositoryProvider = Provider<PinnedEventRepository>((ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return PinnedEventRepositoryImpl(PinnedEventRemoteDatasource(dio));
});

final pinnedEventsNotifierProvider =
    StateNotifierProvider<PinnedEventsNotifier, AsyncValue<Set<String>>>((ref) {
  final repo = ref.watch(pinnedEventRepositoryProvider);
  return PinnedEventsNotifier(repo);
});

class PinnedEventsNotifier extends StateNotifier<AsyncValue<Set<String>>> {
  final PinnedEventRepository _repository;

  PinnedEventsNotifier(this._repository) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    final result = await _repository.getPinnedEvents();
    result.fold(
      (f) => state = AsyncValue.error(f.message, StackTrace.current),
      (events) => state = AsyncValue.data(events.map((e) => e.id).toSet()),
    );
  }

  Future<String?> toggle(String eventId) async {
    final current = state.value ?? {};
    final isPinned = current.contains(eventId);

    // Optimistic update
    final updated = Set<String>.from(current);
    if (isPinned) {
      updated.remove(eventId);
    } else {
      updated.add(eventId);
    }
    state = AsyncValue.data(updated);

    // Backend call
    final result = isPinned
        ? await _repository.unpinEvent(eventId)
        : await _repository.pinEvent(eventId);

    return result.fold(
      (failure) {
        // Revert
        state = AsyncValue.data(Set<String>.from(current));
        return failure.message;
      },
      (_) => null,
    );
  }

  bool isPinned(String eventId) => state.value?.contains(eventId) ?? false;
}
```

**Nota:** Añadir `import '../../../../core/error/failures.dart';` en el test donde se usa `ServerFailure`.

- [ ] **Step 4: Generar mocks y correr tests**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter test test/features/calendar/pinned_events_notifier_test.dart
```

Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/calendar/presentation/providers/pinned_events_provider.dart test/features/calendar/pinned_events_notifier_test.dart
git commit -m "feat: add PinnedEventsNotifier with optimistic update and StateNotifierProvider"
```

---

## Task 8: PinButton widget

**Files:**
- Create: `lib/features/calendar/presentation/widgets/pin_button.dart`

- [ ] **Step 1: Crear PinButton**

```dart
// lib/features/calendar/presentation/widgets/pin_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    final error = await ref.read(pinnedEventsNotifierProvider.notifier).toggle(eventId);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo ${isPinned ? 'desfijar' : 'fijar'} el evento'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
                  Navigator.pushNamed(context, '/login');
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
```

- [ ] **Step 2: Verificar análisis**

```bash
flutter analyze lib/features/calendar/presentation/widgets/pin_button.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/calendar/presentation/widgets/pin_button.dart
git commit -m "feat: add PinButton widget with optimistic animation and guest prompt"
```

---

## Task 9: Convertir EventCard a ConsumerWidget e integrar PinButton

**Files:**
- Modify: `lib/features/calendar/presentation/widgets/event_card.dart`

- [ ] **Step 1: Añadir imports necesarios**

En `event_card.dart`, añadir:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gea_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:gea_app/features/calendar/presentation/widgets/pin_button.dart';
```

- [ ] **Step 2: Cambiar base class a ConsumerWidget**

Cambiar la declaración de la clase:

```dart
// ANTES:
class EventCard extends StatelessWidget {
  final Event event;
  const EventCard({super.key, required this.event});

  void _showEventDetails(BuildContext context) {
    showDetails(context, event);
  }

// DESPUÉS:
class EventCard extends ConsumerWidget {
  final Event event;
  const EventCard({super.key, required this.event});

  void _showEventDetails(BuildContext context, WidgetRef ref) {
    showDetails(context, ref, event);
  }
```

- [ ] **Step 3: Actualizar firma de showDetails**

```dart
// ANTES:
static void showDetails(BuildContext context, Event event) {

// DESPUÉS:
static void showDetails(BuildContext context, WidgetRef ref, Event event) {
```

- [ ] **Step 4: Añadir PinButton en el modal (showDetails)**

Dentro de `showDetails`, después del título del evento (`event.title`), añadir:

```dart
const SizedBox(height: 8),
Consumer(
  builder: (context, ref, _) {
    final isAuthenticated = ref.watch(authProvider).user != null;
    return PinButton(
      eventId: event.id,
      isAuthenticated: isAuthenticated,
      size: 28,
    );
  },
),
```

- [ ] **Step 5: Actualizar el método build**

Cambiar `build(BuildContext context)` a `build(BuildContext context, WidgetRef ref)` y actualizar la llamada a `_showEventDetails`:

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  // ... código existente igual ...
  return InkWell(
    onTap: () => _showEventDetails(context, ref),
    // ...
```

- [ ] **Step 6: Añadir PinButton en la esquina del card (lista)**

En el card de lista, después del thumbnail image (al final del `Row` principal antes de cerrar), añadir PinButton:

```dart
// Al final del Row de contenido, después de la imagen thumbnail:
Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    Consumer(
      builder: (context, ref, _) {
        final isAuthenticated = ref.watch(authProvider).user != null;
        return PinButton(
          eventId: event.id,
          isAuthenticated: isAuthenticated,
        );
      },
    ),
  ],
),
```

- [ ] **Step 7: Actualizar llamadas a showDetails en CalendarScreen**

En `lib/features/calendar/presentation/screens/calendar_screen.dart`, buscar cualquier llamada a `EventCard.showDetails(context, event)` y actualizarla a `EventCard.showDetails(context, ref, event)`.

- [ ] **Step 8: Verificar análisis**

```bash
flutter analyze lib/features/calendar/
```

Expected: `No issues found!`

- [ ] **Step 9: Commit**

```bash
git add lib/features/calendar/presentation/widgets/event_card.dart lib/features/calendar/presentation/screens/calendar_screen.dart
git commit -m "feat: convert EventCard to ConsumerWidget and integrate PinButton"
```

---

## Task 10: PinnedEventsScreen

**Files:**
- Create: `lib/features/calendar/presentation/screens/pinned_events_screen.dart`
- Modify: `lib/config/router/app_router.dart`
- Modify: `lib/features/calendar/presentation/screens/calendar_screen.dart`

- [ ] **Step 1: Crear PinnedEventsScreen**

```dart
// lib/features/calendar/presentation/screens/pinned_events_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:gea_app/core/presentation/widgets/gea_empty_state.dart';
import 'package:gea_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:gea_app/features/calendar/domain/entities/event.dart';
import 'package:gea_app/features/calendar/presentation/providers/pinned_events_provider.dart';
import 'package:gea_app/features/calendar/presentation/widgets/event_card.dart';

class PinnedEventsScreen extends ConsumerWidget {
  const PinnedEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos Fijados'),
        centerTitle: true,
        elevation: 0,
      ),
      body: authState.user == null
          ? _buildGuestView(context, theme)
          : _buildPinnedList(context, ref),
    );
  }

  Widget _buildGuestView(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_outline_rounded, size: 72, color: theme.colorScheme.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 24),
            Text(
              'Inicia sesión para fijar eventos',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Guarda tus eventos favoritos y accede a ellos rápidamente desde aquí.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinnedList(BuildContext context, WidgetRef ref) {
    final pinnedState = ref.watch(pinnedEventsNotifierProvider);
    final eventsAsync = ref.watch(eventsProvider); // import from calendar_providers.dart

    return pinnedState.when(
      loading: () => Skeletonizer(
        enabled: true,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 5,
          itemBuilder: (_, __) => const _PinnedCardSkeleton(),
        ),
      ),
      error: (e, _) => GeaEmptyState(
        icon: Icons.error_outline,
        title: 'Error al cargar',
        subtitle: e.toString(),
        actionLabel: 'Reintentar',
        onAction: () => ref.invalidate(pinnedEventsNotifierProvider),
      ),
      data: (pinnedIds) {
        if (pinnedIds.isEmpty) {
          return const GeaEmptyState(
            icon: Icons.bookmark_outline_rounded,
            title: 'Sin eventos fijados',
            subtitle: 'Toca el ícono de marcador en cualquier evento para guardarlo aquí.',
          );
        }

        return eventsAsync.when(
          loading: () => Skeletonizer(
            enabled: true,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pinnedIds.length,
              itemBuilder: (_, __) => const _PinnedCardSkeleton(),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (events) {
            final pinned = events
                .where((e) => pinnedIds.contains(e.id))
                .toList()
              ..sort((a, b) => a.date.compareTo(b.date));

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pinned.length,
              itemBuilder: (context, i) => EventCard(event: pinned[i]),
            );
          },
        );
      },
    );
  }
}

class _PinnedCardSkeleton extends StatelessWidget {
  const _PinnedCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 88,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
```

- [ ] **Step 2: Añadir ruta en app_router.dart**

En `lib/config/router/app_router.dart`, dentro de las rutas existentes, añadir:

```dart
GoRoute(
  path: '/eventos/fijados',
  builder: (context, state) => const PinnedEventsScreen(),
),
```

Y añadir el import:

```dart
import 'package:gea_app/features/calendar/presentation/screens/pinned_events_screen.dart';
```

- [ ] **Step 4: Añadir botón bookmark en AppBar del CalendarScreen**

En `lib/features/calendar/presentation/screens/calendar_screen.dart`, en el `AppBar`, añadir `actions`:

```dart
AppBar(
  title: const Text('Calendario'),
  centerTitle: true,
  elevation: 0,
  actions: [
    IconButton(
      icon: const Icon(Icons.bookmark_outline_rounded),
      tooltip: 'Eventos fijados',
      onPressed: () => context.push('/eventos/fijados'),
    ),
  ],
),
```

- [ ] **Step 5: Verificar análisis**

```bash
flutter analyze lib/features/calendar/ lib/config/router/
```

Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/features/calendar/presentation/screens/pinned_events_screen.dart lib/features/calendar/presentation/providers/ lib/config/router/app_router.dart lib/features/calendar/presentation/screens/calendar_screen.dart
git commit -m "feat: add PinnedEventsScreen and route /eventos/fijados"
```

---

## Task 11: Marcadores de eventos fijados en el calendario

**Files:**
- Modify: `lib/features/calendar/presentation/screens/calendar_screen.dart`

- [ ] **Step 1: Añadir marcador dorado en días con eventos fijados**

En `calendar_screen.dart`, en el widget `TableCalendar`, dentro de `calendarBuilders`, añadir o actualizar `markerBuilder` para incluir un punto dorado para eventos fijados:

```dart
calendarBuilders: CalendarBuilders(
  markerBuilder: (context, date, events) {
    // Eventos normales del día
    final dayEvents = eventsAsync.value?.where((e) =>
      e.date.year == date.year &&
      e.date.month == date.month &&
      e.date.day == date.day
    ).toList() ?? [];

    // Eventos fijados del día
    final pinnedIds = ref.watch(pinnedEventsNotifierProvider).value ?? {};
    final hasPinned = dayEvents.any((e) => pinnedIds.contains(e.id));

    if (dayEvents.isEmpty) return null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Punto de evento normal
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dayEvents.any((e) => e.isImportant)
                ? AppTheme.importantColor
                : Theme.of(context).colorScheme.primary,
          ),
        ),
        // Punto dorado si hay evento fijado
        if (hasPinned)
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.importantColor,
            ),
          ),
      ],
    );
  },
),
```

Añadir import si no está:

```dart
import 'package:gea_app/features/calendar/presentation/providers/pinned_events_provider.dart';
```

- [ ] **Step 2: Verificar análisis**

```bash
flutter analyze lib/features/calendar/presentation/screens/calendar_screen.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/calendar/presentation/screens/calendar_screen.dart
git commit -m "feat: show pinned event golden dot marker in TableCalendar"
```

---

## Task 12: EventShareCard widget (off-screen render)

**Files:**
- Create: `lib/features/calendar/presentation/widgets/event_share_card.dart`

- [ ] **Step 1: Crear EventShareCard**

```dart
// lib/features/calendar/presentation/widgets/event_share_card.dart
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

  /// Captura el widget como imagen PNG y devuelve los bytes.
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
            // Fondo: imagen o gradiente
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
            // Gradiente oscuro encima
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
            // Contenido
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: nombre institución
                  Row(
                    children: [
                      const Icon(Icons.school_rounded, color: AppTheme.importantColor, size: 18),
                      const SizedBox(width: 6),
                      const Text(
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
                  // Badge categoría
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
                  // Título
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
                  // Fecha y hora
                  _InfoLine(
                    icon: Icons.calendar_today_rounded,
                    text: DateFormat('d MMM yyyy', 'es_ES').format(event.date),
                  ),
                  const SizedBox(height: 4),
                  _InfoLine(
                    icon: Icons.access_time_rounded,
                    text: DateFormat('HH:mm', 'es_ES').format(event.date) +
                        (event.endDate != null ? ' – ${DateFormat('HH:mm', 'es_ES').format(event.endDate!)}' : ''),
                  ),
                  if (event.location != null) ...[
                    const SizedBox(height: 4),
                    _InfoLine(icon: Icons.location_on_outlined, text: event.location!),
                  ],
                  const SizedBox(height: 14),
                  // Tagline
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
```

- [ ] **Step 2: Verificar análisis**

```bash
flutter analyze lib/features/calendar/presentation/widgets/event_share_card.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/features/calendar/presentation/widgets/event_share_card.dart
git commit -m "feat: add EventShareCard off-screen widget for image generation"
```

---

## Task 13: ShareEventBottomSheet e integración en EventCard

**Files:**
- Create: `lib/features/calendar/presentation/widgets/share_event_bottom_sheet.dart`
- Modify: `lib/features/calendar/presentation/widgets/event_card.dart`

- [ ] **Step 1: Crear ShareEventBottomSheet**

```dart
// lib/features/calendar/presentation/widgets/share_event_bottom_sheet.dart
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:gea_app/features/calendar/domain/entities/event.dart';
import 'package:gea_app/features/calendar/presentation/widgets/event_share_card.dart';

class ShareEventBottomSheet extends StatefulWidget {
  final Event event;
  const ShareEventBottomSheet({super.key, required this.event});

  static void show(BuildContext context, Event event) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ShareEventBottomSheet(event: event),
    );
  }

  @override
  State<ShareEventBottomSheet> createState() => _ShareEventBottomSheetState();
}

class _ShareEventBottomSheetState extends State<ShareEventBottomSheet> {
  final _repaintKey = GlobalKey();
  bool _generatingImage = false;

  Future<void> _shareAsImage() async {
    setState(() => _generatingImage = true);
    try {
      final image = await EventShareCard.capture(_repaintKey);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Failed to encode image');

      final bytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/event_share.png');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '📅 ${widget.event.title}\n\nDescárgalo en GEA App',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al generar la imagen')),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingImage = false);
    }
  }

  Future<void> _copyLink() async {
    if (widget.event.link == null) return;
    await Clipboard.setData(ClipboardData(text: widget.event.link!));
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link copiado al portapapeles'),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text('Compartir evento', style: theme.textTheme.titleLarge),
          const SizedBox(height: 20),
          // Vista previa off-screen (necesaria para captura)
          Offstage(
            child: EventShareCard(event: widget.event, repaintKey: _repaintKey),
          ),
          // Opciones
          _ShareOption(
            icon: Icons.image_outlined,
            label: 'Compartir como imagen',
            subtitle: 'Genera una card visual para WhatsApp, Instagram y más',
            isLoading: _generatingImage,
            onTap: _shareAsImage,
          ),
          if (widget.event.link != null) ...[
            const SizedBox(height: 12),
            _ShareOption(
              icon: Icons.link_rounded,
              label: 'Copiar link del stream',
              subtitle: widget.event.link!,
              onTap: _copyLink,
            ),
          ],
        ],
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLoading;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
                    )
                  : Icon(icon, color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Nota:** `share_plus` requiere el paquete `path_provider`. En `pubspec.yaml` dentro de `dependencies:`, añadir:

```yaml
  path_provider: ^2.1.0
```

Luego ejecutar: `flutter pub get`

- [ ] **Step 2: Añadir botón Compartir en el modal de EventCard**

En `event_card.dart`, en el método `showDetails`, añadir al final del `ListView` (antes del cierre), un botón de compartir:

```dart
const SizedBox(height: 24),
SizedBox(
  width: double.infinity,
  child: OutlinedButton.icon(
    onPressed: () {
      Navigator.pop(context);
      ShareEventBottomSheet.show(context, event);
    },
    icon: const Icon(Icons.share_rounded),
    label: const Text('Compartir evento'),
  ),
),
```

Añadir el import:

```dart
import 'package:gea_app/features/calendar/presentation/widgets/share_event_bottom_sheet.dart';
```

- [ ] **Step 3: Verificar análisis completo**

```bash
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/features/calendar/presentation/widgets/share_event_bottom_sheet.dart lib/features/calendar/presentation/widgets/event_card.dart pubspec.yaml pubspec.lock
git commit -m "feat: add ShareEventBottomSheet with image generation and link copy"
```

---

## Verificación final

- [ ] **Correr todos los tests**

```bash
flutter test
```

Expected: All tests PASS.

- [ ] **Análisis final**

```bash
flutter analyze
```

Expected: `No issues found!`

- [ ] **Commit final**

```bash
git add -A
git commit -m "feat: complete event engagement feature (countdown, stream badge, pin, share card)"
```
