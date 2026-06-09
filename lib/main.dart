import 'package:flutter/material.dart';
import 'package:scanning_app/src/app/app.dart';
import 'package:scanning_app/src/core/palm_reading/palm_reading_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PalmReadingService.init();
  runApp(const PalmScannerApp());
}
