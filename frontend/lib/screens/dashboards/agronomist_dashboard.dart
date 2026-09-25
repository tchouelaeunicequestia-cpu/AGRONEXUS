// lib/screens/dashboards/agronomist_dashboard.dart
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_provider.dart';
import '../../services/api_service.dart';

class AgronomistDashboard extends StatefulWidget {
  const AgronomistDashboard({super.key});

  @override
  State<AgronomistDashboard> createState() => _AgronomistDashboardState();
}

class _AgronomistDashboardState extends State<AgronomistDashboard> {
  bool _isLoading = true;
  bool _isBroadcasting = false;
  bool _isFanActive = false;
  Map<String, dynamic> _metrics = {};
  StreamSubscription<Map<String, dynamic>>? _alertSubscription;
  Map<String, dynamic>? _liveAlert;

  @override
  void initState() {
    super.initState();
    _fetchMetrics();
    _subscribeToTelemetryAlerts();
  }

  void _subscribeToTelemetryAlerts() {
    _alertSubscription = ApiService.telemetryAlertStream().listen(
      (alert) {
        if (!mounted) return;
        setState(() => _liveAlert = alert);
        _showCustomSnackBar(
          'Critical telemetry alert from ${alert['nodeId'] ?? 'silo node'}',
        );
      },
      onError: (_) {
        // The static advisory queue remains available if the stream is offline.
      },
    );
  }

  @override
  void dispose() {
    _alertSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchMetrics() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getAgronomistMetrics();
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
                Icons.psychology_rounded,
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
                  'Rag AgroAI',
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
                  'Agronomist / Expert',
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
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF003820)),
            onPressed: () => authProvider.logout(),
            tooltip: 'Sign Out',
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
                              user?.name?.substring(0, 2).toUpperCase() ?? 'SN',
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
                                Row(
                                  children: [
                                    Text(
                                      user?.name ?? 'Dr. Samuel Ngu, Ph.D.',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF003820),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.verified_rounded,
                                      color: Color(0xFF006C49),
                                      size: 18,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Lead Post-Harvest Specialist • IRAD Cameroon',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF404942),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD6EEDC),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'FAO/USDA/UNECE Active RAG',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF005236),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                      childAspectRatio: 2.1,
                      children: [
                        _buildKpiCard(
                          'Open Field Alerts',
                          '${_metrics['openAlerts'] ?? 8}',
                          'High Priority',
                          Icons.notification_important_rounded,
                          const Color(0xFFBA1A1A),
                        ),
                        _buildKpiCard(
                          'RAG Precision',
                          '${_metrics['ragPrecision'] ?? '99.2%'}',
                          'Cosine Index',
                          Icons.model_training_rounded,
                          const Color(0xFF006C49),
                        ),
                        _buildKpiCard(
                          'Storage Nodes',
                          '${_metrics['storageNodes'] ?? 24}',
                          'Live IoT Mesh',
                          Icons.sensors_rounded,
                          const Color(0xFF003820),
                        ),
                        _buildKpiCard(
                          'Loss Prevented',
                          '${_metrics['lossPrevented'] ?? '14 Lots'}',
                          'Validated Saving',
                          Icons.eco_rounded,
                          const Color(0xFFD97706),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.emergency_rounded,
                              color: Color(0xFFBA1A1A),
                              size: 20,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Live Advisory Queue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF003820),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '1 Critical Telemetry',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFBA1A1A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_liveAlert != null) _buildLiveAlertCard(_liveAlert!),
                    if (_liveAlert != null) const SizedBox(height: 12),
                    Container(
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 6,
                              color: const Color(0xFFBA1A1A),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Text(
                                            'TICKET #AGR-401',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF404942),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFDAD6),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'CRITICAL',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFBA1A1A),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Text(
                                        'Node #03 • 4m ago',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF404942),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Silo Microclimate Breach: Bafia Depot',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF003820),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE1FAE7),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.inventory_2_rounded,
                                          size: 18,
                                          color: Color(0xFF003820),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Maize Grain Batch #MZ-44 (12,000 kg) • Sector C, Silo B-4',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF003820),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCF4E1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Rel. Humidity (RH)',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF404942),
                                              ),
                                            ),
                                            const Text(
                                              '85.4% (Limit: ≤ 75%)',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFBA1A1A),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          child: const LinearProgressIndicator(
                                            value: 0.85,
                                            color: Color(0xFFBA1A1A),
                                            backgroundColor: Colors.white,
                                            minHeight: 6,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isBroadcasting
                                          ? const Color(0xFF006C49)
                                          : const Color(0xFF003820),
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(
                                        double.infinity,
                                        48,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () {
                                      setState(() => _isBroadcasting = true);
                                      _showCustomSnackBar(
                                        'Broadcast Confirmed: Protocol sent to 1,402 Farmers.',
                                      );
                                    },
                                    icon: Icon(
                                      _isBroadcasting
                                          ? Icons.done_all_rounded
                                          : Icons.cell_tower_rounded,
                                    ),
                                    label: Text(
                                      _isBroadcasting
                                          ? 'Broadcast Confirmed (1,402 Farmers)'
                                          : 'Broadcast Farmer Protocol SMS + Push',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isFanActive
                                          ? const Color(0xFF003820)
                                          : const Color(0xFF6CF8BB),
                                      foregroundColor: _isFanActive
                                          ? Colors.white
                                          : const Color(0xFF002113),
                                      minimumSize: const Size(
                                        double.infinity,
                                        48,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () {
                                      setState(
                                        () => _isFanActive = !_isFanActive,
                                      );
                                      _showCustomSnackBar(
                                        _isFanActive
                                            ? 'Hardware Relay Confirmed: Silo B-4 extractor online.'
                                            : 'Extractor deactivated.',
                                      );
                                    },
                                    icon: const Icon(Icons.air_rounded),
                                    label: Text(
                                      _isFanActive
                                          ? 'Extractor Fans ACTIVE at 1,800 RPM'
                                          : 'Trigger Silo Extractor Fan (IoT Relay #03)',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLiveAlertCard(Map<String, dynamic> alert) {
    final nodeId = alert['nodeId']?.toString() ?? 'Unknown node';
    final humidity = alert['humidity']?.toString() ?? '--';
    final temperature = alert['temperature']?.toString() ?? '--';
    final gas = alert['gasLevel']?.toString() ?? '--';

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F2).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB4AB)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFBA1A1A),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LIVE TELEMETRY BREACH',
                  style: TextStyle(
                    color: Color(0xFFBA1A1A),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$nodeId • RH $humidity% • $temperature°C • Gas $gas',
                  style: const TextStyle(
                    color: Color(0xFF003820),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  alert['alertMessage']?.toString() ??
                      'Environmental parameters exceed the safe threshold.',
                  style: const TextStyle(
                    color: Color(0xFF404942),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Dismiss live alert',
            onPressed: () => setState(() => _liveAlert = null),
            icon: const Icon(Icons.close, color: Color(0xFFBA1A1A)),
          ),
        ],
      ),
        ),
      ),
    );
  }

  Widget _buildKpiCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF404942),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)),
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }
}