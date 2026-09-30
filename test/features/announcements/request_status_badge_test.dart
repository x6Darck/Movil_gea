import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gea_app/features/announcements/domain/entities/request_status.dart';
import 'package:gea_app/features/announcements/presentation/widgets/request_status_badge.dart';

void main() {
  Future<void> pump(WidgetTester tester, RequestStatus status) {
    return tester.pumpWidget(MaterialApp(
      home: Scaffold(body: RequestStatusBadge(status: status)),
    ));
  }

  testWidgets('muestra la etiqueta correcta por estado', (tester) async {
    await pump(tester, RequestStatus.enRevision);
    expect(find.text('En revisión'), findsOneWidget);

    await pump(tester, RequestStatus.rechazada);
    expect(find.text('Rechazada'), findsOneWidget);

    await pump(tester, RequestStatus.aprobada);
    expect(find.text('Aprobada'), findsOneWidget);

    await pump(tester, RequestStatus.publicada);
    expect(find.text('Publicada'), findsOneWidget);

    await pump(tester, RequestStatus.pendiente);
    expect(find.text('Pendiente'), findsOneWidget);
  });
}
