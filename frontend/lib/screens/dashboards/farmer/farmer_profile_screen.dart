import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/services/auth_provider.dart';
import 'package:frontend/widgets/farmer_background_layer.dart';
import 'package:frontend/widgets/farmer_bottom_navigation.dart';

import 'farmer_dashboard.dart';
import 'farmer_escrow_screen.dart';
import 'farmer_listings_screen.dart';
import 'farmer_telemetry_screen.dart';
import '../../../screens/produce/add_produce_screen.dart';

class FarmerProfileScreen extends StatefulWidget {
  const FarmerProfileScreen({super.key});

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _initialized = false;
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final user = context.read<AuthProvider>().currentUser;
      _nameController.text = user?.name ?? '';
      _phoneController.text = user?.phoneNumber ?? '';
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      _showMessage('Full name is required.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      await context.read<AuthProvider>().updateCurrentUserProfile(
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );
      if (mounted) _showMessage('Profile updated.');
    } catch (error) {
      if (mounted)
        _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: FarmerBottomNavigation(
        selectedIndex: 5,
        onDestinationSelected: _navigateToFarmerTab,
      ),
      body: Stack(
        children: [
          const FarmerBackgroundLayer(),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: const Color(0xD90B1326),
                foregroundColor: Colors.white,
                title: const Text('Producer profile'),
                actions: [
                  IconButton(
                    tooltip: 'Log out',
                    onPressed: () => context.read<AuthProvider>().logout(),
                    icon: const Icon(Icons.logout_rounded),
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _profileHero(user),
                    const SizedBox(height: 24),
                    const Text(
                      'Account details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _field(
                      'Full name',
                      _nameController,
                      Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 12),
                    _field(
                      'Phone number',
                      _phoneController,
                      Icons.phone_outlined,
                    ),
                    const SizedBox(height: 12),
                    _readOnlyField(
                      'Email address',
                      user?.email ?? '',
                      Icons.email_outlined,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _saveProfile,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('Save changes'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: const Color(0xFF003824),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Account actions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => context.read<AuthProvider>().logout(),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Log out'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToFarmerTab(int index) {
    if (index == 5) return;
    final Widget screen = switch (index) {
      0 => const FarmerDashboard(),
      1 => const FarmerListingsScreen(),
      2 => const AddProduceScreen(),
      3 => const FarmerEscrowScreen(),
      4 => const FarmerTelemetryScreen(),
      _ => const FarmerDashboard(),
    };
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Widget _profileHero(dynamic user) {
    final name = user?.name?.toString().trim();
    final initial = name?.isNotEmpty == true ? name![0].toUpperCase() : 'F';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF171F33).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF4EDEA3).withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: const Color(0xFF4EDEA3),
            child: Text(
              initial,
              style: const TextStyle(
                color: Color(0xFF003824),
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name?.isNotEmpty == true ? name! : 'Producer account',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(
                      Icons.agriculture_rounded,
                      color: Color(0xFF6CF8BB),
                      size: 15,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Farmer account',
                      style: TextStyle(
                        color: Color(0xFF6CF8BB),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
    IconData icon,
  ) => TextField(
    controller: controller,
    style: const TextStyle(color: Colors.white),
    decoration: _decoration(label, icon),
  );

  Widget _readOnlyField(String label, String value, IconData icon) =>
      InputDecorator(
        decoration: _decoration(label, icon).copyWith(
          suffixIcon: const Icon(
            Icons.lock_outline_rounded,
            color: Colors.white38,
          ),
        ),
        child: Text(
          value.isEmpty ? 'Not provided' : value,
          style: const TextStyle(color: Colors.white70),
        ),
      );

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white70),
    prefixIcon: Icon(icon, color: const Color(0xFF6CF8BB)),
    filled: true,
    fillColor: Colors.black.withValues(alpha: 0.58),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Colors.white24),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF6CF8BB)),
    ),
  );
}
