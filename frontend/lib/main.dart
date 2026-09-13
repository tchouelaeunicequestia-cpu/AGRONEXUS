import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'services/auth_provider.dart';

// Import your future dashboard screens here
// import 'screens/dashboards/farmer_dashboard.dart';
// import 'screens/dashboards/buyer_dashboard.dart';

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

          // FR1.3: Role-Based Access Control Dashboard Router
          switch (auth.role) {
            case 'FARMER':
              return const RoleDashboardPlaceholder(roleTitle: 'Farmer Dashboard');
            case 'BUYER':
              return const RoleDashboardPlaceholder(roleTitle: 'Buyer Marketplace');
            case 'TRANSPORTER':
              return const RoleDashboardPlaceholder(roleTitle: 'Transporter Logistics Hub');
            case 'AGRONOMIST':
              return const RoleDashboardPlaceholder(roleTitle: 'Agronomist Advisory Console');
            case 'ADMIN':
              return const RoleDashboardPlaceholder(roleTitle: 'System Admin Control Panel');
            default:
              return const RoleDashboardPlaceholder(roleTitle: 'General Dashboard');
          }
        },
      ),
    );
  }
}

class RoleDashboardPlaceholder extends StatelessWidget {
  final String roleTitle;
  const RoleDashboardPlaceholder({super.key, required this.roleTitle});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: Text(roleTitle),
        backgroundColor: Colors.green.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user, size: 64, color: Colors.green.shade700),
            const SizedBox(height: 16),
            Text(
              'Welcome to $roleTitle',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Enforced RBAC Role: ${auth.role}'),
          ],
        ),
      ),
    );
  }
}