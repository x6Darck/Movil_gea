import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gea_app/core/presentation/widgets/gea_floating_nav_bar.dart';

void main() {
  testWidgets('GeaFloatingNavBar renderiza items y reporta seleccion', (tester) async {
    int tapped = -1;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: GeaFloatingNavBar(
          selectedIndex: 0,
          onDestinationSelected: (i) => tapped = i,
          items: const [
            GeaNavItem(icon: Icons.calendar_today_outlined, selectedIcon: Icons.calendar_today, label: 'Cal'),
            GeaNavItem(icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Perfil'),
            GeaNavItem(icon: Icons.campaign_outlined, selectedIcon: Icons.campaign, label: 'Anuncios'),
          ],
        ),
      ),
    ));

    expect(find.text('Cal'), findsOneWidget); // label visible solo en el seleccionado
    await tester.tap(find.byIcon(Icons.person_outline));
    expect(tapped, 1);
  });
}
