import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gea_app/core/presentation/widgets/gea_glass_card.dart';

void main() {
  testWidgets('GeaGlassCard renderiza su child y responde al tap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: GeaGlassCard(
          onTap: () => tapped = true,
          child: const Text('contenido'),
        ),
      ),
    ));
    expect(find.text('contenido'), findsOneWidget);
    await tester.tap(find.text('contenido'));
    expect(tapped, true);
  });
}
