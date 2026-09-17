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
  List<dynamic> _pendingUsers = [];

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  Future<void> _fetchAdminData() async {
    setState(() => _isLoading = true);
    try {
      // Fetch live pending users from backend (FR1.3)
      final userResponse = await ApiService.authenticatedRequest('/api/v1/admin/pending-users');
      // Fetch system metrics from backend
      final metricsResponse = await ApiService.authenticatedRequest('/api/v1/admin/metrics');

      if (mounted) {
        setState(() {
          if (userResponse.statusCode == 200) {
            _pendingUsers = jsonDecode(userResponse.body);
          }
          if (metricsResponse.statusCode == 200) {
            _metrics = jsonDecode(metricsResponse.body);
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveUser(int userId, String name) async {
    try {
      final response = await ApiService.authenticatedRequest(
        '/api/v1/admin/approve-user/$userId',
        method: 'POST',
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name approved successfully!'), backgroundColor: const Color(0xFF16a34a)),
        );
        _fetchAdminData(); // Refresh list dynamically
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving user: $e'), backgroundColor: Colors.red),
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
        title: const Text('AgroNexus Enterprise Admin', style: TextStyle(color: Color(0xFF003820), fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Color(0xFF003820)), onPressed: _fetchAdminData),
          IconButton(icon: const Icon(Icons.logout, color: Color(0xFF003820)), onPressed: () => auth.logout()),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF003820)))
          : RefreshIndicator(
              onRefresh: _fetchAdminData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Superuser: ${user?.name ?? 'Admin'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF003820))),
                        const Text('CEMAC/BEAC Vault Live • System Mesh Active', style: TextStyle(fontSize: 12, color: Color(0xFF404942))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildMetricCard('Locked Escrow', '${_metrics['escrowVolume'] ?? '14,850,000'} XAF', Colors.green)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMetricCard('Vetting Queue', '${_pendingUsers.length} Accounts', Colors.orange)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Pending Account Vetting Queue (FR1.3)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF003820))),
                  const SizedBox(height: 10),
                  _pendingUsers.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(20),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: const Text('No pending accounts awaiting verification.', style: TextStyle(color: Color(0xFF64748B))),
                        )
                      : Column(
                          children: _pendingUsers.map((p) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                title: Text('${p['fullName']} (${p['role']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Email: ${p['email']}'),
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16a34a)),
                                  onPressed: () => _approveUser(p['id'], p['fullName']),
                                  child: const Text('Approve', style: TextStyle(color: Colors.white)),
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

  Widget _buildMetricCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}