// =============================================================================
// FeedFormulatorApp – root MaterialApp widget
// =============================================================================

import 'package:flutter/material.dart';

import 'screens/home/home_screen.dart';

/// The root of the application. Configures Material 3 theming and sets
/// [FormulatorHomePage] as the entry route.
class FeedFormulatorApp extends StatelessWidget {
  const FeedFormulatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Feed Formulator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        cardTheme: CardThemeData(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const FormulatorHomePage(),
    );
  }
}
