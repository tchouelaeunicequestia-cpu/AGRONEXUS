// lib/screens/dashboards/admin_dashboard.dart
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/auth_provider.dart';
import 'package:frontend/services/draft_service.dart';
import 'package:frontend/services/platform_services.dart';
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
        _fetchAdminData();
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

    // Extract live metrics safely with 0 fallback instead of fake static numbers
    final double escrowVolume = (_metrics['escrowVolume'] is num)
        ? (_metrics['escrowVolume'] as num).toDouble()
        : 0.0;
    final String activeOrderCode = _metrics['activeOrderCode']?.toString() ?? 'ORD-LIVE-PENDING';

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.6),
        elevation: 0,
        toolbarHeight: 64,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: const Icon(
                Icons.admin_panel_settings_rounded,
                color: Colors.white,
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
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Command Center',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 6,
                  height: 6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFF6CF8BB),
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
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _fetchAdminData,
            tooltip: 'Refresh data',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () => auth.logout(),
            tooltip: 'Sign out',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              'https://img.freepik.com/premium-photo/agriculture-project-africa_943281-36244.jpg?w=2000',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0F382C)),
            ),
          ),
          SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : _errorMessage != null
                    ? _buildErrorState()
                    : RefreshIndicator(
                        onRefresh: _fetchAdminData,
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 26,
                                        backgroundColor: const Color(0xFF16A34A),
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
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            const Text(
                                              'Operations, trust & compliance control plane',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white70,
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
                                                      color: Color(0xFF6CF8BB),
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
                                                    color: Color(0xFF6CF8BB),
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
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMetricCard(
                                    'Locked Escrow',
                                    '${escrowVolume.toStringAsFixed(2)} XAF',
                                    Colors.greenAccent,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildMetricCard(
                                    'Vetting Queue',
                                    '$pendingCount accounts',
                                    Colors.orangeAccent,
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
                                    Colors.lightBlueAccent,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildMetricCard(
                                    'Products',
                                    '${_metrics['productCount'] ?? 0}',
                                    Colors.tealAccent,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildMetricCard(
                                    'Orders',
                                    '${_metrics['orderCount'] ?? 0}',
                                    Colors.purpleAccent,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildMetricCard(
                              'Telemetry Alerts',
                              '${_metrics['telemetryAlertCount'] ?? 0}',
                              Colors.redAccent,
                            ),
                            const SizedBox(height: 20),
                            
                            // ESCROW GOVERNANCE SETTLEMENT PANEL
                            const Text(
                              'Escrow Governance Settlement',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            AdminEscrowPanel(
                              orderDetails: {
                                'orderCode': activeOrderCode,
                                'totalEscrowAmount': escrowVolume,
                              },
                              adminAuthToken: ApiService.globalAccessToken ?? '',
                              adminUserId: user?.id?.toString() ?? '1',
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
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '$pendingCount pending',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orangeAccent,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Review network access and manage account trust status.',
                              style: TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                            const SizedBox(height: 10),
                            if (_users.isEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                                  child: Container(
                                    padding: const EdgeInsets.all(24),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                                    ),
                                    child: const Column(
                                      children: [
                                        Icon(
                                          Icons.verified_user_outlined,
                                          size: 36,
                                          color: Color(0xFF6CF8BB),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'All accounts are up to date.',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            else
                              ..._users.map(_buildUserCard),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 48, color: Colors.redAccent),
                const SizedBox(height: 12),
                const Text(
                  'Admin data could not be loaded.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _fetchAdminData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: Colors.white70),
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
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isVerified
                  ? Colors.greenAccent.withOpacity(0.3)
                  : Colors.orangeAccent.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white.withOpacity(0.15),
                child: Text(
                  name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
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
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${account['email']} • $role',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
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
                      ? Colors.orangeAccent
                      : const Color(0xFF6CF8BB),
                  side: BorderSide(
                    color: isVerified
                        ? Colors.orangeAccent.withOpacity(0.5)
                        : const Color(0xFF6CF8BB).withOpacity(0.5),
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

/// Admin Escrow Panel UI Widget for executing live 85% / 15% splits
class AdminEscrowPanel extends StatefulWidget {
  final Map<String, dynamic> orderDetails;
  final String adminAuthToken;
  final String adminUserId;

  const AdminEscrowPanel({
    Key? key,
    required this.orderDetails,
    required this.adminAuthToken,
    required this.adminUserId,
  }) : super(key: key);

  @override
  State<AdminEscrowPanel> createState() => _AdminEscrowPanelState();
}

class _AdminEscrowPanelState extends State<AdminEscrowPanel> {
  bool _isProcessing = false;

  Future<void> _processAdminEscrowRelease() async {
    setState(() => _isProcessing = true);
    final orderCode = widget.orderDetails['orderCode'];

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/v1/admin/escrow/release/$orderCode'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.adminAuthToken}',
          'X-Admin-User-Id': widget.adminUserId,
        },
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Escrow successfully released: 85% Farmer / 15% Transporter split processed.'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
      } else {
        String errorMessage = 'Server error (${response.statusCode})';
        if (response.body.isNotEmpty) {
          try {
            final body = jsonDecode(response.body);
            errorMessage = body['error'] ?? body['message'] ?? errorMessage;
          } catch (_) {
            errorMessage = response.body;
          }
        }
        throw Exception(errorMessage);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action failed: $error'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double total = (widget.orderDetails['totalEscrowAmount'] ?? 0.0).toDouble();
    final double farmerSplit = total * 0.85;
    final double transporterSplit = total * 0.15;
    final String orderCode = widget.orderDetails['orderCode'] ?? 'N/A';

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin Escrow Governance & Settlement',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Text('Order Reference: $orderCode'),
            const SizedBox(height: 8),
            Text('Total Pool Protected: ${total.toStringAsFixed(2)} XAF'),
            Text('Calculated Farmer Share (85%): ${farmerSplit.toStringAsFixed(2)} XAF'),
            Text('Calculated Transporter Share (15%): ${transporterSplit.toStringAsFixed(2)} XAF'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: (_isProcessing || total <= 0) ? null : _processAdminEscrowRelease,
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(total <= 0 ? 'No Active Escrow Pool' : 'Authorize & Signoff Escrow Release'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}