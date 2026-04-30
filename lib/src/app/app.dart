import 'package:flutter/material.dart';
import 'package:scanning_app/src/core/theme/app_theme.dart';
import 'package:scanning_app/src/features/home/presentation/home_shell_screen.dart';

class PalmScannerApp extends StatelessWidget {
  const PalmScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Palm Reading AI',
      theme: AppTheme.lightTheme,
      home: const HomeShellScreen(),
    );
  }
}
