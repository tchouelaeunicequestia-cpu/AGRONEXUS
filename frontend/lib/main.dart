import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/login_screen.dart';
import 'services/auth_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..tryAutoLogin()),
      ],
      child: const AgroNexusApp(),
    ),
  );
}

class AgroNexusApp extends StatelessWidget {
  const AgroNexusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgroNexus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (!auth.isAuthenticated) {
            return const LoginScreen();
          }

          // Placeholder screen until role dashboards are rendered
          return Scaffold(
            appBar: AppBar(
              title: Text('AgroNexus - ${auth.role ?? "Dashboard"}'),
              backgroundColor: Colors.green.shade800,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => auth.logout(),
                ),
              ],
            ),
            body: Center(
              child: Text(
                'Authenticated as Role: ${auth.role}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
