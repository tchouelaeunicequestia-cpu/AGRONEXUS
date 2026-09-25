// lib/screens/dashboards/transporter_dashboard.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/platform_services.dart';

class TransporterDashboard extends StatefulWidget {
  const TransporterDashboard({super.key});

  @override
  State<TransporterDashboard> createState() => _TransporterDashboardState();
}

class _TransporterDashboardState extends State<TransporterDashboard> {
  bool _isLoading = true;
  Map<String, dynamic> _metrics = {};
  PositionData? _livePosition;
  List<Map<String, dynamic>> _quoteRequests = [];

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchMetrics(),
      _fetchQuoteRequests(),
      _loadLivePosition(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchQuoteRequests() async {
    try {
      final orders = await ApiService.getTransportQuoteRequests();
      if (mounted) setState(() => _quoteRequests = orders);
    } catch (_) {}
  }

  Future<void> _loadLivePosition() async {
    try {
      final position = await LocationServiceFactory.getService().getCurrentLocation();
      if (mounted) setState(() => _livePosition = position);
    } catch (_) {}
  }

  Future<void> _fetchMetrics() async {
    try {
      final response = await ApiService.authenticatedRequest('/api/v1/transporter/metrics');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          setState(() => _metrics = data);
        }
      }
    } catch (_) {}
  }

  Future<void> _showQuoteDialog(Map<String, dynamic> order) async {
    final controller = TextEditingController();
    final fee = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Submit Quote: ${order['orderCode']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product: ${order['productTitle']} (${order['quantity']} units)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Destination: ${order['deliveryAddress']}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Transport Fee (XAF)',
                hintText: 'e.g. 15000',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
            onPressed: () => Navigator.pop(context, double.tryParse(controller.text)),
            child: const Text('Submit Quote', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    controller.dispose();
    if (fee == null || fee < 0) return;

    try {
      await ApiService.submitTransportQuote(
        orderCode: order['orderCode'],
        transportFee: fee,
      );
      _showCustomSnackBar('Transport quote successfully submitted to buyer.');
      await _fetchQuoteRequests();
    } catch (error) {
      _showCustomSnackBar(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showCustomSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF003820),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.6),
        elevation: 0,
        toolbarHeight: 64,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
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
              ),
              child: const Icon(
                Icons.local_shipping_rounded,
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
                  'Freight & Logistics Corridor',
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
                  'Transporter / Fleet',
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
            onPressed: _fetchAllData,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () => authProvider.logout(),
            tooltip: 'Sign Out',
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
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : RefreshIndicator(
                  onRefresh: _fetchAllData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile & Live GPS Widget
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 26,
                                        backgroundColor: const Color(0xFF16A34A),
                                        child: Text(
                                          (user?.name?.isNotEmpty ?? false)
                                              ? user!.name!.substring(0, 2).toUpperCase()
                                              : 'TR',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              user?.name ?? 'Transporter Fleet Node',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            const Text(
                                              'Logistics & Freight Corridor Hub',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.gps_fixed, color: Color(0xFF6CF8BB), size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _livePosition != null
                                                ? 'Live GPS: ${_livePosition!.latitude.toStringAsFixed(4)}° N, ${_livePosition!.longitude.toStringAsFixed(4)}° E'
                                                : 'Acquiring live RTK corridor coordinates...',
                                            style: const TextStyle(fontSize: 11, color: Colors.white70),
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
                        const SizedBox(height: 16),

                        // Metrics Summary Cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                'Pending Jobs',
                                '${_quoteRequests.length}',
                                Colors.orangeAccent,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricCard(
                                'Active Route',
                                _metrics['odometer']?.toString() ?? '142 km',
                                Colors.greenAccent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Available Transport Quote Requests / Delivery Jobs
                        const Text(
                          'Available Delivery Jobs & Quote Requests',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),

                        if (_quoteRequests.isEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
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
                                    Icon(Icons.local_shipping_outlined, size: 36, color: Color(0xFF6CF8BB)),
                                    SizedBox(height: 8),
                                    Text(
                                      'No pending transport quote requests.',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'New freight orders will appear here automatically.',
                                      style: TextStyle(color: Colors.white60, fontSize: 12),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else
                          ..._quoteRequests.map((order) => ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              order['orderCode'] ?? 'ORD-REF',
                                              style: const TextStyle(
                                                color: Color(0xFF6CF8BB),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.orange.withOpacity(0.4)),
                                              ),
                                              child: const Text(
                                                'Quote Pending',
                                                style: TextStyle(fontSize: 10, color: Colors.orangeAccent, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${order['productTitle']} (${order['quantity']} units)',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on_outlined, size: 14, color: Colors.white70),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                order['deliveryAddress'] ?? 'Delivery Destination',
                                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 14),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF16A34A),
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                            onPressed: () => _showQuoteDialog(order),
                                            icon: const Icon(Icons.local_shipping, size: 16),
                                            label: const Text('Submit Freight Quote'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )),
                        const SizedBox(height: 20),

                        // FR4.2: Active Freight Corridor & State Tracking Panel
                        _buildActiveDeliveriesSection(),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildActiveDeliveriesSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Active Freight Corridor & State Tracking',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Monitor order delivery states across CEMAC transit zones.',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
              const SizedBox(height: 16),
              _buildStateTimelineStep('Escrow Locked', 'Funds secured in trust vault', true),
              _buildStateTimelineStep('Dispatched', 'Transporter assigned to pickup', true),
              _buildStateTimelineStep('In Transit', 'En route to buyer hub via corridor', true),
              _buildStateTimelineStep('Delivered', 'Handover at destination completed', false),
              _buildStateTimelineStep('Completed', 'Escrow disbursed (85% Farmer / 15% Transporter)', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStateTimelineStep(String title, String subtitle, bool isComplete) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isComplete ? const Color(0xFF16A34A) : Colors.white.withOpacity(0.2),
            ),
            child: Icon(
              isComplete ? Icons.check : Icons.hourglass_empty,
              size: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isComplete ? Colors.white : Colors.white60,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isComplete ? Colors.white70 : Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
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
}