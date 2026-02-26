import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pruefungsduell/app/app.dart';

void main() {
  Widget createApp() => const PruefungsduellApp();

  testWidgets('App startet mit Login-Seite', (WidgetTester tester) async {
    await tester.pumpWidget(createApp());

    expect(find.text('Prüfungsduell'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Anmelden'), findsOneWidget);
  });

  testWidgets('Login-Validierung zeigt Fehlermeldung bei leerem Formular', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createApp());

    await tester.tap(find.text('Anmelden'));
    await tester.pumpAndSettle();

    expect(find.text('Bitte E-Mail eingeben'), findsOneWidget);
    expect(find.text('Bitte Passwort eingeben'), findsOneWidget);
  });

  testWidgets('Login-Validierung zeigt Fehlermeldung bei ungültiger E-Mail', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createApp());

    final emailField = find.byType(TextFormField).first;
    final passwordField = find.byType(TextFormField).at(1);

    await tester.enterText(emailField, 'invalid-email');
    await tester.enterText(passwordField, '123456');
    await tester.tap(find.text('Anmelden'));
    await tester.pumpAndSettle();

    expect(find.text('Bitte eine gültige E-Mail eingeben'), findsOneWidget);
  });

  testWidgets('Navigiert von Login zu RegisterPage', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createApp());

    await tester.tap(find.text('Noch kein Konto? Jetzt registrieren'));
    await tester.pumpAndSettle();

    // AppBar-Titel und Button-Text enthalten "Registrieren"
    expect(find.text('Registrieren'), findsWidgets);
    expect(find.byType(TextFormField), findsNWidgets(3));
  });
}
