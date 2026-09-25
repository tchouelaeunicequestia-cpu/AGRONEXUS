// lib/screens/dashboards/admin_dashboard.dart
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_provider.dart';
import '../../services/api_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _isLoading = true;
  Map<String, dynamic> _metrics = {};
  List<dynamic> _users = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  Future<void> _fetchAdminData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final userResponse = await ApiService.authenticatedRequest(
        '/api/v1/admin/users',
      );
      // Fetch system metrics from backend
      final metricsResponse = await ApiService.authenticatedRequest(
        '/api/v1/admin/metrics',
      );

      if (userResponse.statusCode != 200 || metricsResponse.statusCode != 200) {
        throw StateError(
          'Unable to load admin data '
          '(users: ${userResponse.statusCode}, '
          'metrics: ${metricsResponse.statusCode}).',
        );
      }

      final users = jsonDecode(userResponse.body);
      final metrics = jsonDecode(metricsResponse.body);
      if (users is! List || metrics is! Map<String, dynamic>) {
        throw const FormatException(
          'The admin API returned an invalid response.',
        );
      }

      if (mounted) {
        setState(() {
          _users = users;
          _metrics = metrics;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = error.toString();
        });
      }
    }
  }

  Future<void> _setUserVerification(
    int userId,
    String name,
    bool shouldApprove,
  ) async {
    try {
      final response = await ApiService.authenticatedRequest(
        '/api/v1/admin/${shouldApprove ? 'approve' : 'deapprove'}-user/$userId',
        method: 'POST',
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$name ${shouldApprove ? 'approved' : 'de-approved'} successfully!',
            ),
            backgroundColor: const Color(0xFF16a34a),
          ),
        );
        _fetchAdminData(); // Refresh list dynamically
      } else {
        final body = jsonDecode(response.body);
        throw StateError(
          body is Map<String, dynamic>
              ? body['error']?.toString() ?? 'Unable to update account status.'
              : 'Unable to update account status.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating account status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final pendingCount = _users
        .where((account) => account['isVerified'] == false)
        .length;

    return Scaffold(
      backgroundColor: Colors.black, // Fallback color
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.85),
        elevation: 0,
        toolbarHeight: 64,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF003820).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.admin_panel_settings_rounded,
                color: Color(0xFF003820),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AgroNexus',
                  style: TextStyle(
                    color: Color(0xFF003820),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Command Center',
                  style: TextStyle(color: Color(0xFF404942), fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFD6EEDC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 6,
                  height: 6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFF006C49),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  'Admin / Control',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF005236),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF003820)),
            onPressed: _fetchAdminData,
            tooltip: 'Refresh data',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF003820)),
            onPressed: () => auth.logout(),
            tooltip: 'Sign out',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // BOTTOM LAYER: Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/farm_background.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0F382C)),
            ),
          ),
          // TOP LAYER: Original UI (untouched)
          _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF003820)),
            )
          : _errorMessage != null
          ? _buildErrorState()
          : RefreshIndicator(
              onRefresh: _fetchAdminData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: const Color(0xFF003820),
                          child: Text(
                            (user?.name?.isNotEmpty ?? false)
                                ? user!.name!.substring(0, 1).toUpperCase()
                                : 'A',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.name ?? 'System Administrator',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF003820),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Operations, trust & compliance control plane',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF404942),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Row(
                                children: [
                                  SizedBox(
                                    width: 7,
                                    height: 7,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: Color(0xFF006C49),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'System mesh active',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF006C49),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          'Locked Escrow',
                          '${_metrics['escrowVolume'] ?? 0} XAF',
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          'Vetting Queue',
                          '$pendingCount accounts',
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          'Users',
                          '${_metrics['userCount'] ?? 0}',
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          'Products',
                          '${_metrics['productCount'] ?? 0}',
                          Colors.teal,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          'Orders',
                          '${_metrics['orderCount'] ?? 0}',
                          Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildMetricCard(
                    'Telemetry Alerts',
                    '${_metrics['telemetryAlertCount'] ?? 0}',
                    Colors.red,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Account Verification',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003820),
                        ),
                      ),
                      Text(
                        '$pendingCount pending',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Review network access and manage account trust status.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 10),
                  if (_users.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            size: 36,
                            color: Color(0xFF006C49),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'All accounts are up to date.',
                            style: TextStyle(
                              color: Color(0xFF404942),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._users.map(_buildUserCard),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            const Text(
              'Admin data could not be loaded.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchAdminData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.55),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(dynamic account) {
    final isVerified = account['isVerified'] == true;
    final isAdmin = account['role'] == 'ADMIN';
    final name = account['fullName']?.toString() ?? 'Unknown account';
    final role = account['role']?.toString() ?? 'USER';

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isVerified ? const Color(0xFFD6EEDC) : const Color(0xFFFDE68A),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isVerified
                ? const Color(0xFFD6EEDC)
                : const Color(0xFFFEF3C7),
            child: Text(
              name.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF003820),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003820),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${account['email']} • $role',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: isAdmin && isVerified
                ? null
                : () => _setUserVerification(account['id'], name, !isVerified),
            style: OutlinedButton.styleFrom(
              foregroundColor: isVerified
                  ? const Color(0xFFB45309)
                  : const Color(0xFF006C49),
              side: BorderSide(
                color: isVerified
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF006C49),
              ),
            ),
            child: Text(isVerified ? 'De-approve' : 'Approve'),
          ),
        ],
      ),
        ),
      ),
    );
  }
}