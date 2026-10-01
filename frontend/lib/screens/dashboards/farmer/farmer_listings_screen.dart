import 'package:flutter/material.dart';
import 'package:frontend/screens/produce/add_produce_screen.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/draft_service.dart';

class FarmerListingsScreen extends StatefulWidget {
  const FarmerListingsScreen({super.key});

  @override
  State<FarmerListingsScreen> createState() => _FarmerListingsScreenState();
}

class _FarmerListingsScreenState extends State<FarmerListingsScreen> {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _drafts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  Future<void> _loadListings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        ApiService.getFarmerProducts(),
        DraftService.loadDrafts(),
      ]);
      if (!mounted) return;
      setState(() {
        _products = results[0] as List<Map<String, dynamic>>;
        _drafts = results[1] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _openAddProduce() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddProduceScreen()),
    );
    if (result == true || mounted) _loadListings();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _appBar(),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _summaryCard(),
              const SizedBox(height: 18),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: Color(0xFF6CF8BB)),
                  ),
                )
              else if (_errorMessage != null)
                _messageCard(_errorMessage!)
              else ...[
                _sectionTitle('Published harvest lots', _products.length),
                const SizedBox(height: 10),
                if (_products.isEmpty)
                  _emptyCard(
                    'No active lots yet. Publish your first harvest lot.',
                  )
                else
                  ..._products.map(_productCard),
                if (_drafts.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _sectionTitle('Drafts', _drafts.length),
                  const SizedBox(height: 10),
                  ..._drafts.map((draft) => _draftCard(draft)),
                ],
              ],
            ]),
          ),
        ),
      ],
    );
  }

  Widget _appBar() => SliverAppBar(
    pinned: true,
    backgroundColor: Colors.black.withValues(alpha: 0.72),
    foregroundColor: Colors.white,
    title: const Text('My harvest lots'),
    actions: [
      IconButton(
        tooltip: 'Refresh listings',
        onPressed: _isLoading ? null : _loadListings,
        icon: const Icon(Icons.refresh_rounded),
      ),
    ],
  );

  Widget _summaryCard() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFF0F382C).withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFF6CF8BB).withValues(alpha: 0.3)),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.inventory_2_rounded,
          color: Color(0xFF6CF8BB),
          size: 30,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '${_products.length + _drafts.length} total items in your producer workspace',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        FilledButton.icon(
          onPressed: _openAddProduce,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF16A34A),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    ),
  );

  Widget _sectionTitle(String title, int count) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      Text(
        '$count',
        style: const TextStyle(
          color: Color(0xFF6CF8BB),
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );

  Widget _productCard(Map<String, dynamic> product) => _listingCard(
    title: product['title']?.toString() ?? 'Produce lot',
    subtitle:
        '${product['availableQuantity'] ?? 0} ${product['unitType'] ?? 'kg'} available',
    detail:
        '${product['pricePerUnit'] ?? 0} XAF / ${product['unitType'] ?? 'kg'}',
    status: 'ACTIVE',
    icon: Icons.eco_rounded,
  );

  Widget _draftCard(Map<String, dynamic> draft) => _listingCard(
    title: draft['title']?.toString() ?? 'Untitled draft',
    subtitle:
        '${draft['availableQuantity'] ?? 0} ${draft['unitType'] ?? 'kg'} planned',
    detail: '${draft['pricePerUnit'] ?? 0} XAF / ${draft['unitType'] ?? 'kg'}',
    status: 'DRAFT',
    icon: Icons.edit_note_rounded,
  );

  Widget _listingCard({
    required String title,
    required String subtitle,
    required String detail,
    required String status,
    required IconData icon,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.62),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
    ),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: const Color(0xFF16A34A).withValues(alpha: 0.2),
          child: Icon(icon, color: const Color(0xFF6CF8BB)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                detail,
                style: const TextStyle(
                  color: Color(0xFF6CF8BB),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Chip(
          label: Text(status),
          labelStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          backgroundColor: status == 'ACTIVE'
              ? const Color(0xFFDCFCE7)
              : const Color(0xFFFEF3C7),
          side: BorderSide.none,
        ),
      ],
    ),
  );

  Widget _emptyCard(String message) =>
      _messageCard(message, icon: Icons.inventory_2_outlined);

  Widget _messageCard(
    String message, {
    IconData icon = Icons.error_outline_rounded,
  }) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.62),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
    ),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFF6CF8BB)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(message, style: const TextStyle(color: Colors.white70)),
        ),
      ],
    ),
  );
}
