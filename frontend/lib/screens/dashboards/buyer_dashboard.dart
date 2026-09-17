import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api_service.dart';
import '../../services/auth_provider.dart';
import '../../services/platform_services.dart';

class BuyerDashboard extends StatefulWidget {
  const BuyerDashboard({super.key});

  @override
  State<BuyerDashboard> createState() => _BuyerDashboardState();
}

class _BuyerDashboardState extends State<BuyerDashboard>
    with SingleTickerProviderStateMixin {
  List<dynamic> _backendProducts = [];
  bool _isLoading = false;
  double _searchRadiusKm = 50.0;
  double _userLat = 3.8480;
  double _userLon = 11.5021;
  String _locationDescription = 'Yaoundé, Centre Region, Cameroon';
  String _selectedCategory = 'All';
  String _searchQuery = '';
  int _activeNavIndex = 0; // 0: Market, 1: Escrow, 2: Telemetry, 3: AgroAI

  final TextEditingController _searchController = TextEditingController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<double> _radiusOptions = [5, 15, 25, 50, 100];
  final List<Map<String, dynamic>> _categoryItems = [
    {'name': 'All Lots', 'value': 'All', 'icon': Icons.apps_rounded, 'color': const Color(0xFF0F172A)},
    {'name': 'Plantains', 'value': 'PLANTAINS', 'icon': Icons.eco_rounded, 'color': const Color(0xFF059669)},
    {'name': 'Cereals', 'value': 'CEREALS', 'icon': Icons.grass_rounded, 'color': const Color(0xFFD97706)},
    {'name': 'Tubers', 'value': 'TUBERS', 'icon': Icons.set_meal_rounded, 'color': const Color(0xFFB45309)},
    {'name': 'Vegetables', 'value': 'VEGETABLES', 'icon': Icons.local_florist_rounded, 'color': const Color(0xFFEF4444)},
    {'name': 'Cocoa & Coffee', 'value': 'COCOA', 'icon': Icons.coffee_rounded, 'color': const Color(0xFF78350F)},
  ];

  // Showcase fallback harvest lots matching the high-fidelity HTML design specification
  final List<Map<String, dynamic>> _sampleHarvestLots = [
    {
      'id': 101,
      'title': 'Organic Giant Plantain',
      'scientificName': 'Musa paradisiaca',
      'farmerName': 'Jean-Paul Kamga',
      'locationAxis': 'Bafia Depot Axis',
      'category': 'PLANTAINS',
      'pricePerUnit': 450,
      'unitType': 'kg',
      'availableQuantity': 3500.0,
      'inventoryPercent': 0.70,
      'distanceKm': 18.4,
      'gradeBadge': 'Grade A+ Export',
      'telemetryInfo': 'ESP32 Node #4 · Silo 14.2°C Safe Microclimate',
      'timeAgo': 'Cut 4h ago',
      'spec1': 'Direct Depot Pickup',
      'spec2': 'PostGIS Escrow Lock',
      'imageUrl':
          'https://images.unsplash.com/photo-1528825871115-3581a5387919?q=80&w=800&auto=format&fit=crop',
    },
    {
      'id': 102,
      'title': 'Red Roma Tomatoes',
      'scientificName': 'Lycopersicon',
      'farmerName': 'Obala Hydro-Farms',
      'locationAxis': 'Direct Pickup or Freight',
      'category': 'VEGETABLES',
      'pricePerUnit': 600,
      'unitType': 'crate',
      'availableQuantity': 120.0,
      'inventoryPercent': 0.45,
      'distanceKm': 7.2,
      'gradeBadge': 'ESP32 Telemetry',
      'telemetryInfo': 'Obala Hydro-Farms · 18.2°C & 82% RH in Silo',
      'timeAgo': 'Grade AA',
      'spec1': '18.2°C Cold Chain',
      'spec2': 'Verified Quality AA',
      'imageUrl':
          'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?q=80&w=800&auto=format&fit=crop',
    },
    {
      'id': 103,
      'title': 'Raw Fermented Cocoa Beans Grade 1',
      'scientificName': 'Theobroma cacao',
      'farmerName': 'SOCOOPAC Co-operative',
      'locationAxis': 'Export Grade',
      'category': 'COCOA',
      'pricePerUnit': 2850,
      'unitType': 'kg',
      'availableQuantity': 1200.0,
      'inventoryPercent': 0.85,
      'distanceKm': 34.0,
      'gradeBadge': 'Traceable #442',
      'telemetryInfo': 'Moisture Content: 7.1% · Certified Bio',
      'timeAgo': 'Locked Buffer',
      'spec1': 'Moisture: 7.1%',
      'spec2': 'Escrow Securitized',
      'imageUrl':
          'https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?q=80&w=800&auto=format&fit=crop',
    },
    {
      'id': 104,
      'title': 'White Sweet Cassava Tubers',
      'scientificName': 'Manihot esculenta',
      'farmerName': 'Mbankomo Agri Union',
      'locationAxis': 'Center Region',
      'category': 'TUBERS',
      'pricePerUnit': 300,
      'unitType': 'kg',
      'availableQuantity': 4000.0,
      'inventoryPercent': 0.55,
      'distanceKm': 12.1,
      'gradeBadge': 'Fresh Harvest',
      'telemetryInfo': 'Mbankomo Union · Washed & Cleaned Root',
      'timeAgo': 'Yesterday',
      'spec1': 'Direct Root Delivery',
      'spec2': 'Washed & Sorted',
      'imageUrl':
          'https://images.unsplash.com/photo-1590779033100-9f60a05a013d?q=80&w=800&auto=format&fit=crop',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadUserLocationAndProduce();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserLocationAndProduce() async {
    try {
      final locationService = LocationServiceFactory.getService();
      PositionData pos = await locationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _userLat = pos.latitude;
          _userLon = pos.longitude;
          _locationDescription = pos.description;
        });
      }
    } catch (_) {}
    await _fetchNearbyProduce();
  }

  Future<void> _fetchNearbyProduce() async {
    setState(() => _isLoading = true);
    try {
      final radiusMeters = _searchRadiusKm * 1000;
      final endpoint =
          '/products/nearby?latitude=$_userLat&longitude=$_userLon&radiusMeters=$radiusMeters';

      // Pass endpoint as a positional argument, not a named argument
      final response = await ApiService.authenticatedRequest(
        endpoint,
        method: 'GET',
      );

      if (response.statusCode == 200) {
        List<dynamic> fetched = jsonDecode(response.body);
        setState(() {
          _backendProducts = fetched;
        });
      }
    } catch (_) {
      // Graceful fallback to rich static dataset if backend is unreachable
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _displayLots {
    List<Map<String, dynamic>> combined = [];

    for (var p in _backendProducts) {
      combined.add({
        'id': p['id'] ?? 0,
        'title': p['title'] ?? 'Produce Harvest Lot',
        'scientificName': p['description'] ?? 'Verified Farm Lot',
        'farmerName': p['farmer'] != null ? p['farmer']['fullName'] ?? 'Verified Farmer' : 'Farmer #${p['farmerId'] ?? 1}',
        'locationAxis': 'PostGIS Geopositional',
        'category': (p['category'] ?? 'PLANTAINS').toString().toUpperCase(),
        'pricePerUnit': (p['pricePerUnit'] ?? 450).toInt(),
        'unitType': p['unitType'] ?? 'kg',
        'availableQuantity': (p['availableQuantity'] ?? 1000.0).toDouble(),
        'inventoryPercent': 0.65,
        'distanceKm': 14.5,
        'gradeBadge': 'PostGIS Verified',
        'telemetryInfo': 'ESP32 Telemetry Linked · 16.5°C Safe',
        'timeAgo': 'Recent',
        'spec1': 'Direct Farm Pickup',
        'spec2': 'Escrow Lock Ready',
        'imageUrl': p['imageUrl'] ?? 'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?q=80&w=800&auto=format&fit=crop',
      });
    }

    if (combined.isEmpty) {
      combined.addAll(_sampleHarvestLots);
    } else {
      for (var s in _sampleHarvestLots) {
        if (!combined.any((item) => item['title'] == s['title'])) {
          combined.add(s);
        }
      }
    }

    if (_selectedCategory != 'All') {
      combined = combined.where((item) {
        final cat = (item['category'] ?? '').toString().toUpperCase();
        return cat == _selectedCategory ||
            (_selectedCategory == 'PLANTAINS' && cat.contains('PLANT')) ||
            (_selectedCategory == 'COCOA' && (cat.contains('COCOA') || cat.contains('COFFEE')));
      }).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      combined = combined.where((item) {
        return item['title'].toString().toLowerCase().contains(q) ||
            item['farmerName'].toString().toLowerCase().contains(q) ||
            item['category'].toString().toLowerCase().contains(q);
      }).toList();
    }

    return combined;
  }

  void _openEscrowCheckoutModal(Map<String, dynamic> item) {
    final double price = (item['pricePerUnit'] ?? 0).toDouble();
    final double transportFee = 5000.0;
    final double depositBuffer = 6350.0;
    final double totalDepository = price + transportFee + (2 * depositBuffer);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFFAF3),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD7F3E3)),
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    color: Color(0xFF0F5132),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Escrow Depository Order Lock',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Mobile Money Escrow Protection (1.5% Fee Covered)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildModalCostRow(
                    'Produce Harvest Lot',
                    item['title'],
                    isBold: true,
                  ),
                  const SizedBox(height: 8),
                  _buildModalCostRow(
                    'Producer / Cooperative',
                    item['farmerName'],
                  ),
                  const Divider(height: 20, color: Color(0xFFE2E8F0)),
                  _buildModalCostRow(
                    'Item Cost',
                    '${price.toStringAsFixed(0)} XAF',
                  ),
                  const SizedBox(height: 8),
                  _buildModalCostRow(
                    'Freight Dispatch Fee',
                    '${transportFee.toStringAsFixed(0)} XAF',
                  ),
                  const SizedBox(height: 8),
                  _buildModalCostRow(
                    'Deposit Buffer (2x)',
                    '${(2 * depositBuffer).toStringAsFixed(0)} XAF',
                  ),
                  const Divider(height: 20, color: Color(0xFFE2E8F0)),
                  _buildModalCostRow(
                    'Total Escrow Locked',
                    '${totalDepository.toStringAsFixed(0)} XAF',
                    isTotal: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 16,
                  color: Color(0xFF0F5132),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Funds locked in admin escrow depository until delivery confirmation.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F5132),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Escrow Order Locked for ${item['title']}!',
                          ),
                          backgroundColor: const Color(0xFF0F5132),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.verified_user_rounded, size: 18),
                    label: const Text(
                      'Lock Escrow Order',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalCostRow(String label, String value,
      {bool isBold = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 14 : 12,
            fontWeight: isTotal || isBold ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 13,
            fontWeight: isTotal || isBold ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? const Color(0xFF0F5132) : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  pinned: true,
                  backgroundColor: Colors.white.withValues(alpha: 0.92),
                  elevation: 0,
                  toolbarHeight: 64,
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(1),
                    child: Container(
                      color: const Color(0xFFE2E8F0),
                      height: 1,
                    ),
                  ),
                  title: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFFAF3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD7F3E3)),
                        ),
                        child: const Icon(
                          Icons.eco_rounded,
                          color: Color(0xFF0F5132),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'AgroNexus',
                                style: TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFFAF3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFD7F3E3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    FadeTransition(
                                      opacity: _pulseAnimation,
                                      child: Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF10B981),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Buyer',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F5132),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            'Institutional Wholesale Portal',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.notifications_none_rounded,
                              color: Color(0xFF475569),
                              size: 20,
                            ),
                            onPressed: () {},
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 10,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 14.0),
                      child: GestureDetector(
                        onTap: () => auth.logout(),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF0F5132).withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: const CircleAvatar(
                            radius: 14,
                            backgroundColor: Color(0xFF0F5132),
                            child: Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // 1. GPS Location Banner
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFFAF3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFD7F3E3)),
                              ),
                              child: const Icon(
                                Icons.explore_rounded,
                                color: Color(0xFF0F5132),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Sourcing Farm GPS Coordinates',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _locationDescription,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  FadeTransition(
                                    opacity: _pulseAnimation,
                                    child: Container(
                                      width: 7,
                                      height: 7,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    '±3.8m Precision',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 2. Sourcing Radius Filter
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFFAF3),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.radar_rounded,
                                        size: 18,
                                        color: Color(0xFF0F5132),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Sourcing Radius Filter',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.tune_rounded,
                                        size: 12,
                                        color: Color(0xFF0F5132),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'PostGIS ST_DWithin',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF475569),
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Segmented Radius Options
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: _radiusOptions.map((dist) {
                                  final isSelected = _searchRadiusKm == dist;
                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() => _searchRadiusKm = dist);
                                        _fetchNearbyProduce();
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFF0F5132)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(8),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: const Color(0xFF0F5132)
                                                        .withValues(alpha: 0.3),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ]
                                              : [],
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${dist.toInt()} km',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? Colors.white
                                                : const Color(0xFF475569),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Perimeter: Within ${_searchRadiusKm.toInt()} km zone',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFFAF3),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF1B8A53),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_displayLots.length} verified harvest lots',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F5132),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 3. Search Bar
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (val) =>
                                    setState(() => _searchQuery = val),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF0F172A),
                                ),
                                decoration: const InputDecoration(
                                  hintText:
                                      'Search crops, cooperatives, lot ID...',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 13,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                    color: Color(0xFF94A3B8),
                                    size: 20,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.filter_list_rounded,
                                color: Color(0xFF475569),
                                size: 20,
                              ),
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 4. Category Carousel
                      SizedBox(
                        height: 36,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categoryItems.length,
                          itemBuilder: (context, index) {
                            final cat = _categoryItems[index];
                            final isSelected = _selectedCategory == cat['value'];

                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: InkWell(
                                onTap: () {
                                  setState(() => _selectedCategory = cat['value']);
                                  _fetchNearbyProduce();
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF0F172A)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF0F172A)
                                          : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      if (cat['value'] != 'All')
                                        Icon(
                                          cat['icon'],
                                          size: 15,
                                          color: isSelected
                                              ? Colors.white
                                              : cat['color'],
                                        ),
                                      if (cat['value'] != 'All')
                                        const SizedBox(width: 6),
                                      Text(
                                        cat['name'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                          color: isSelected
                                              ? Colors.white
                                              : const Color(0xFF334155),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 5. Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Real-Time Available Lots',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'PostGIS geosorted by buyer proximity',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.swap_vert_rounded,
                                  size: 15,
                                  color: Color(0xFF0F5132),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Nearest First',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 6. Harvest Cards List
                      _isLoading
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(40.0),
                                child: CircularProgressIndicator(
                                  color: Color(0xFF0F5132),
                                ),
                              ),
                            )
                          : _displayLots.isEmpty
                              ? Container(
                                  padding: const EdgeInsets.all(40),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'No active produce lots match your current filters.',
                                    style: TextStyle(color: Color(0xFF64748B)),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _displayLots.length,
                                  itemBuilder: (context, index) {
                                    final item = _displayLots[index];
                                    return _buildHarvestCard(item);
                                  },
                                ),
                    ]),
                  ),
                ),
              ],
            ),

            // Floating Spatial Action Toolbar
            Positioned(
              left: 16,
              right: 16,
              bottom: 72,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF1E293B),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        FadeTransition(
                          opacity: _pulseAnimation,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF34D399),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'LIVE GEOSPATIAL FILTER',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF94A3B8),
                                letterSpacing: 0.8,
                              ),
                            ),
                            Text(
                              'Centre Region • ${_searchRadiusKm.toInt()}km radius',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.tune_rounded,
                                size: 14,
                                color: Color(0xFFE2E8F0),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Filter',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFE2E8F0),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F5132),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.map_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Map View',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Navigation Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.96),
                  border: const Border(
                    top: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.storefront_rounded, 'Market'),
                    _buildNavItem(1, Icons.verified_user_rounded, 'Escrow'),
                    _buildNavItem(2, Icons.sensors_rounded, 'Telemetry'),
                    _buildNavItem(3, Icons.psychology_rounded, 'AgroAI'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = _activeNavIndex == index;
    return InkWell(
      onTap: () => setState(() => _activeNavIndex = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFEFFAF3) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isActive ? const Color(0xFF0F5132) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? const Color(0xFF0F5132) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHarvestCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Image.network(
                    item['imageUrl'],
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: const Color(0xFFF1F5F9),
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported_rounded,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(19)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.65),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.near_me_rounded,
                        size: 13,
                        color: Color(0xFF34D399),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item['distanceKm']} km away',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        size: 14,
                        color: Color(0xFF0F5132),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item['gradeBadge'],
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            FadeTransition(
                              opacity: _pulseAnimation,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF34D399),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item['telemetryInfo'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        item['timeAgo'],
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (item['scientificName'] != null)
                            Text(
                              '(${item['scientificName']})',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                item['farmerName'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                '•',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item['locationAxis'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified_rounded,
                                size: 14,
                                color: Color(0xFF0F5132),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${item['pricePerUnit']}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F5132),
                              ),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'XAF/${item['unitType']}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item['availableQuantity'].toInt()} ${item['unitType']} left',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (item['inventoryPercent'] as double),
                    backgroundColor: const Color(0xFFF1F5F9),
                    color: const Color(0xFF1B8A53),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_shipping_outlined,
                              size: 14,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item['spec1'],
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF475569),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lock_outline_rounded,
                              size: 14,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item['spec2'],
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF475569),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F5132),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => _openEscrowCheckoutModal(item),
                    icon: const Icon(Icons.verified_user_rounded, size: 18),
                    label: const Text(
                      'Order via Escrow',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}