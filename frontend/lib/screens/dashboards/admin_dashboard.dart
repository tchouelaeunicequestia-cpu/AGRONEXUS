// lib/screens/dashboards/admin_dashboard.dart
import 'dart:convert';

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
          '(pending users: ${userResponse.statusCode}, '
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

    return Scaffold(
      backgroundColor: const Color(0xFFE9FFED),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'AgroNexus Enterprise Admin',
          style: TextStyle(
            color: Color(0xFF003820),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF003820)),
            onPressed: _fetchAdminData,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF003820)),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: _isLoading
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
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Superuser: ${user?.name ?? 'Admin'}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003820),
                          ),
                        ),
                        const Text(
                          'CEMAC/BEAC Vault Live • System Mesh Active',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF404942),
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
                          '${_users.where((u) => u['isVerified'] == false).length} Accounts',
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
                  const Text(
                    'Account Verification Management',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003820),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _users.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(20),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'No pending accounts awaiting verification.',
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        )
                      : Column(
                          children: _users.map((p) {
                            final isVerified = p['isVerified'] == true;
                            final isAdmin = p['role'] == 'ADMIN';
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                title: Text(
                                  '${p['fullName']} (${p['role']})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text('Email: ${p['email']}'),
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isVerified
                                        ? Colors.orange
                                        : const Color(0xFF16a34a),
                                  ),
                                  onPressed: isAdmin && isVerified
                                      ? null
                                      : () => _setUserVerification(
                                          p['id'],
                                          p['fullName'],
                                          !isVerified,
                                        ),
                                  child: Text(
                                    isVerified ? 'De-approve' : 'Approve',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ],
              ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
    );
  }
}
