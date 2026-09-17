// lib/screens/dashboards/transporter_dashboard.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/api_service.dart';

class TransporterDashboard extends StatefulWidget {
  const TransporterDashboard({super.key});

  @override
  State<TransporterDashboard> createState() => _TransporterDashboardState();
}

class _TransporterDashboardState extends State<TransporterDashboard> {
  bool _isLoading = true;
  bool _isRadarActive = true;
  Map<String, dynamic> _metrics = {};

  @override
  void initState() {
    super.initState();
    _fetchMetrics();
  }

  Future<void> _fetchMetrics() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getTransporterMetrics();
      if (mounted) {
        setState(() {
          _metrics = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCustomSnackBar(String message) {
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
      backgroundColor: const Color(0xFFE9FFED),
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
              child: const Icon(Icons.local_shipping_rounded, color: Color(0xFF003820), size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('AgroNexus', style: TextStyle(color: Color(0xFF003820), fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Freight Mesh', style: TextStyle(color: Color(0xFF404942), fontSize: 11)),
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
                SizedBox(width: 6, height: 6, child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFF006C49), shape: BoxShape.circle))),
                SizedBox(width: 6),
                Text('Transporter / Fleet', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF005236))),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF003820)),
            onPressed: () => authProvider.logout(),
            tooltip: 'Sign Out',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF003820)))
          : RefreshIndicator(
              onRefresh: _fetchMetrics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  SizedBox(width: 8, height: 8, child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFF006C49), shape: BoxShape.circle))),
                                  SizedBox(width: 8),
                                  Text('Freight Mesh v2.6 Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF006C49))),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFFD6EEDC), borderRadius: BorderRadius.circular(10)),
                                child: const Text('RTK ±1.8m', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF003820))),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(user?.name ?? 'Jean-Baptiste Ndongo', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF003820))),
                                    const SizedBox(height: 2),
                                    const Text('Isuzu NPR 4.5T Coldbox • CMR-LT-884-AB', style: TextStyle(fontSize: 12, color: Color(0xFF404942))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _buildKpiCard('Escrow Locked', '${_metrics['lockedEscrow'] ?? '100,000 XAF'}', 'Guaranteed Payout', Icons.lock_rounded, const Color(0xFF003820)),
                        _buildKpiCard('Cold Chain Telemetry', '${_metrics['temp'] ?? '8.2°C'}', '100% Compliant', Icons.ac_unit_rounded, const Color(0xFF006C49)),
                        _buildKpiCard('Odometer Today', '${_metrics['odometer'] ?? '142 km'}', 'Avg 58 km/h', Icons.speed_rounded, const Color(0xFF404942)),
                        _buildKpiCard('Dispatched Slots', '${_metrics['jobs'] ?? 2} Jobs', '1 Live • 1 Queued', Icons.inventory_2_rounded, const Color(0xFF003820)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Active Corridor Missions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF003820))),
                        Text('FR4.1 & FR4.2 Protocol', style: TextStyle(fontSize: 11, color: Color(0xFF404942))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFF6CF8BB), borderRadius: BorderRadius.circular(10)),
                                child: const Text('IN TRANSIT #ORD-2026-A89F', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF002113))),
                              ),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('35,000 XAF', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003820))),
                                  Text('15% Escrow Release', style: TextStyle(fontSize: 10, color: Color(0xFF006C49))),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text('Organic Giant Plantain', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF003820))),
                          const Text('3,500 kg • 70 Standardized Cold Crates', style: TextStyle(fontSize: 12, color: Color(0xFF404942))),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF003820),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 44),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _showCustomSnackBar('Waypoint #3 Logged: PK84 +3.854°N, 11.512°E'),
                            icon: const Icon(Icons.add_location_alt_rounded),
                            label: const Text('Submit Geotagged Waypoint', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildKpiCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 18),
              const Icon(Icons.trending_up_rounded, color: Color(0xFF16a34a), size: 14),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 10, color: Color(0xFF404942), fontWeight: FontWeight.w500), maxLines: 1),
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
              Text(subtitle, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)), maxLines: 1),
            ],
          ),
        ],
      ),
    );
  }
}