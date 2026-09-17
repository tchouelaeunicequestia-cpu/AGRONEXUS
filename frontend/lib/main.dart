// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboards/farmer_dashboard.dart';
import 'screens/dashboards/buyer_dashboard.dart';
import 'screens/dashboards/transporter_dashboard.dart';
import 'screens/dashboards/agronomist_dashboard.dart';
import 'screens/dashboards/admin_dashboard.dart';
import 'services/auth_provider.dart';
import 'theme/app_theme.dart';

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
      theme: AppTheme.lightTheme,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (!auth.isAuthenticated) {
            return const LoginScreen();
          }

          // FR1.3: Role-Based Access Control Dashboard Router
          switch (auth.role) {
            case 'FARMER':
              return const FarmerDashboard();
            case 'BUYER':
              return const BuyerDashboard();
            case 'TRANSPORTER':
              return const TransporterDashboard();
            case 'AGRONOMIST':
              return const AgronomistDashboard();
            case 'ADMIN':
              return const AdminDashboard();
            default:
              return const RoleDashboardPlaceholder(
                roleTitle: 'General Dashboard',
                icon: Icons.dashboard_outlined,
                accentColor: AppTheme.primaryEmerald,
              );
          }
        },
      ),
    );
  }
}

class RoleDashboardPlaceholder extends StatelessWidget {
  final String roleTitle;
  final IconData icon;
  final Color accentColor;

  const RoleDashboardPlaceholder({
    super.key,
    required this.roleTitle,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    final displayName = user?.name ?? 'User';
    final email = user?.email ?? 'No email available';
    final initials = displayName.trim().isEmpty
        ? '?'
        : displayName.trim().substring(0, 1).toUpperCase();
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        flexibleSpace: const FlexibleSpaceBar(
          background: DecoratedBox(
            decoration: BoxDecoration(gradient: AppTheme.headerGradient),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.eco_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(roleTitle),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.lightBorder),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  roleTitle,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkSlate,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '$displayName\n$email\nAuthenticated RBAC Role: ${auth.role}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.mutedGrey,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: AppTheme.successGreen, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your authenticated AgroNexus profile is active.',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryEmerald),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}