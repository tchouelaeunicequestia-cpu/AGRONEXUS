import 'package:flutter/material.dart';
import 'screens/test_screen.dart';

void main() {
  runApp(const AgroNexusApp());
}

class AgroNexusApp extends StatelessWidget {
  const AgroNexusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgroNexus',
      theme: ThemeData(primarySwatch: Colors.green),
      home: TestScreen(),
    );
  }
}