import 'package:flutter/material.dart';
import 'package:pruefungsduell/features/auth/presentation/pages/login_page.dart';

class PruefungsduellApp extends StatelessWidget {
  const PruefungsduellApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prüfungsduell',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}
