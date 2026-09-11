import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'screens/test_screen.dart';
import 'services/auth_provider.dart'; // Import your new class

void main() {
  runApp(
    // MultiProvider allows you to add more providers later (like CartProvider)
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const AgroNexusApp(),
    ),
  );
}

class AgroNexusApp extends StatelessWidget {
  const AgroNexusApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgroNexus',
      theme: ThemeData(primarySwatch: Colors.green),
      home: TestScreen(), 
    );
  }
}