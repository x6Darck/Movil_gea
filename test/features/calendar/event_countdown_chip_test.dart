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

    test('returns "En curso" when endDate is null and now is within 1h window', () {
      final now = DateTime.now();
      final label = EventCountdownChip.computeLabel(
        date: now.subtract(const Duration(minutes: 20)),
        endDate: null,
        now: now,
      );
      expect(label, 'En curso');
    });

    test('returns "Faltan 7 días" when event is exactly 7 days away', () {
      final now = DateTime.now();
      final label = EventCountdownChip.computeLabel(
        date: now.add(const Duration(days: 7)),
        endDate: null,
        now: now,
      );
      expect(label, 'Faltan 7 días');
    });
  });
}
