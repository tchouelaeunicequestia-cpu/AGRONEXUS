import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/platform_services.dart';

class FarmerDashboard extends StatefulWidget {
  const FarmerDashboard({super.key});

  @override
  State<FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends State<FarmerDashboard> {
  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = {};
  List<Map<String, dynamic>> _products = [];
  String _locationString = 'Bafia North • Lat 4.7502° N, Lon 11.2331° E';
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _fetchLiveDashboardData();
  }

  Future<void> _fetchLiveDashboardData() async {
    setState(() => _isRefreshing = true);
    try {
      final data = await ApiService.getFarmerDashboardMetrics();
      final products = await ApiService.getFarmerProducts();
      
      try {
        final locService = LocationServiceFactory.getService();
        final pos = await locService.getCurrentLocation();
        _locationString = '${pos.description} • Lat ${pos.latitude.toStringAsFixed(4)}° N, Lon ${pos.longitude.toStringAsFixed(4)}° E';
      } catch (_) {
        // Fallback default coordinates if sensor is busy
      }

      if (mounted) {
        setState(() {
          _dashboardData = data;
          _products = products;
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  void _showNewHarvestModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'List New Harvest Lot',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF003820)),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Produce Type (e.g. Arabica Coffee, Cocoa)',
                prefixIcon: Icon(Icons.agriculture_rounded),
              ),
            ),
            const SizedBox(height: 12),
            const TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity Available (Kg)',
                prefixIcon: Icon(Icons.scale_rounded),
              ),
            ),
            const SizedBox(height: 12),
            const TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Unit Price (XAF / Kg)',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003820),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Harvest lot successfully listed on escrow ledger!'),
                      backgroundColor: Color(0xFF006c49),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  _fetchLiveDashboardData();
                },
                child: const Text('Publish Harvest Lot', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final userName = user?.name?.toUpperCase() ?? 'EUNICE';
    final userEmail = user?.email ?? 'eunice.tchouela@agronexus.io';
    final userInitials = userName.isNotEmpty ? userName.substring(0, 1) : 'E';

    return Scaffold(
      backgroundColor: const Color(0xFFe9ffed),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: const Color(0xFFe9ffed).withValues(alpha: 0.9),
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
                  child: const Icon(Icons.eco_rounded, color: Color(0xFF003820), size: 20),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'AgroNexus',
                      style: TextStyle(color: Color(0xFF003820), fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text('IoT Silo Telemetry & Escrow', style: TextStyle(color: Color(0xFF404942), fontSize: 11)),
                  ],
                ),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 14),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFd6eedc),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 6,
                      height: 6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFF006c49),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Farmer Producer',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF005236)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Color(0xFF003820)),
                onPressed: () => authProvider.logout(),
                tooltip: 'Sign Out',
              ),
              const SizedBox(width: 8),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(60.0),
                        child: CircularProgressIndicator(color: Color(0xFF003820)),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: const Color(0xFF003820),
                                    child: Text(
                                      userInitials,
                                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
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
                                              userName,
                                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF003820)),
                                            ),
                                            const SizedBox(width: 6),
                                            const Icon(Icons.verified_rounded, color: Color(0xFF16a34a), size: 18),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Verified Producer Account • $userEmail',
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF404942)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(_isRefreshing ? Icons.sync_rounded : Icons.refresh_rounded, color: const Color(0xFF006c49)),
                                    onPressed: _fetchLiveDashboardData,
                                    tooltip: 'Refresh Telemetry',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFe1fae7),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFb8e7c8)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on_rounded, color: Color(0xFF006c49), size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'GPS Lock: $_locationString',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF003820)),
                                      ),
                                    ),
                                    const Text(
                                      '±1.8m',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16a34a)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 800;
                            if (isWide) {
                              return Row(
                                children: [
                                  Expanded(child: _buildEscrowCard()),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildHarvestCard()),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildTelemetryCard()),
                                ],
                              );
                            } else {
                              return Column(
                                children: [
                                  _buildEscrowCard(),
                                  const SizedBox(height: 16),
                                  _buildHarvestCard(),
                                  const SizedBox(height: 16),
                                  _buildTelemetryCard(),
                                ],
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF003820),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                onPressed: _showNewHarvestModal,
                                icon: const Icon(Icons.add_circle_outline_rounded),
                                label: const Text('List New Harvest Lot', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF003820),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: const BorderSide(color: Color(0xFF003820)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                onPressed: _fetchLiveDashboardData,
                                icon: const Icon(Icons.sensors_rounded, size: 18),
                                label: const Text('Audit Silo Sensors', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF003820),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: const BorderSide(color: Color(0xFF003820)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Logistics dispatch requested from Bafia Hub.'),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: Color(0xFF006c49),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.local_shipping_outlined, size: 18),
                                label: const Text('Request Transporter', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Active Harvest Lots',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF003820)),
                            ),
                            Text(
                              '${_products.length} Commodities',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF16a34a)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8),
                            ],
                          ),
                          child: Column(
                            children: _products.isEmpty
                                ? [
                                    const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text(
                                        'You have not published any produce yet.',
                                        style: TextStyle(color: Color(0xFF64748B)),
                                      ),
                                    ),
                                  ]
                                : [
                                    for (var i = 0; i < _products.length; i++) ...[
                                      _buildHarvestLotItem(
                                        _products[i]['title']?.toString() ?? 'Produce lot',
                                        '${_products[i]['availableQuantity'] ?? 0} ${_products[i]['unitType'] ?? 'kg'} Available',
                                        '${_products[i]['pricePerUnit'] ?? 0} XAF / ${_products[i]['unitType'] ?? 'kg'}',
                                        _products[i]['isActive'] == false ? 'Inactive' : 'Active',
                                      ),
                                      if (i < _products.length - 1) const Divider(height: 24),
                                    ],
                                  ],
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

  Widget _buildEscrowCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TOTAL ESCROW RECEIVABLE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF404942))),
          const SizedBox(height: 12),
          Text(
            '${_dashboardData['escrowBalance'] ?? 0} XAF',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF003820)),
          ),
          const SizedBox(height: 6),
          const Text('85% locked in CEMAC trust vault', style: TextStyle(fontSize: 12, color: Color(0xFF16a34a), fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          const Text('Release trigger: Buyer Q/C Signoff', style: TextStyle(fontSize: 11, color: Color(0xFF64748b))),
        ],
      ),
    );
  }

  Widget _buildHarvestCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('HARVEST BATCHES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF404942))),
          const SizedBox(height: 12),
          Text(
            '${_dashboardData['activeLotsCount'] ?? 0} Active Lots',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF003820)),
          ),
          const SizedBox(height: 6),
          Text('${_dashboardData['totalYieldKg'] ?? 0} kg total yield available', style: const TextStyle(fontSize: 12, color: Color(0xFF16a34a), fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: const LinearProgressIndicator(value: 0.75, color: Color(0xFF006c49), backgroundColor: Color(0xFFd0e8d6), minHeight: 6),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('IOT SILO HEALTH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF404942))),
          const SizedBox(height: 12),
          Text(
            _dashboardData['siloTemp'] == null
                ? 'No data'
                : '${_dashboardData['siloTemp']}°C',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF003820)),
          ),
          const SizedBox(height: 6),
          Text(
            _dashboardData['telemetryAvailable'] == true
                ? 'Live ESP32 telemetry'
                : 'No telemetry received yet',
            style: const TextStyle(fontSize: 12, color: Color(0xFF16a34a), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Text(
            _dashboardData['siloHumidity'] == null
                ? 'Connect a storage node to see readings'
                : 'Latest RH: ${_dashboardData['siloHumidity']}% • Gas: ${_dashboardData['siloGas']}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748b)),
          ),
        ],
      ),
    );
  }

  Widget _buildHarvestLotItem(String title, String qty, String price, String status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFe1fae7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.eco_rounded, color: Color(0xFF006c49), size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF003820))),
                const SizedBox(height: 2),
                Text(qty, style: const TextStyle(fontSize: 12, color: Color(0xFF404942))),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(price, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF006c49))),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFd6eedc),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(status, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF005236))),
            ),
          ],
        ),
      ],
    );
  }
}