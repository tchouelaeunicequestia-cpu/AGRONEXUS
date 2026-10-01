import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/services/auth_provider.dart';

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
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: Colors.black.withValues(alpha: 0.72),
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
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Center(
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: const Color(0xFF16A34A),
                  child: Text(
                    (user?.name?.isNotEmpty == true ? user!.name![0] : 'F')
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  user?.email ?? 'Producer account',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 24),
              _field(
                'Full name',
                _nameController,
                Icons.person_outline_rounded,
              ),
              const SizedBox(height: 12),
              _field('Phone number', _phoneController, Icons.phone_outlined),
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
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Save changes'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
              const SizedBox(height: 28),
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

  Widget _readOnlyField(String label, String value, IconData icon) => TextField(
    controller: TextEditingController(text: value),
    readOnly: true,
    style: const TextStyle(color: Colors.white70),
    decoration: _decoration(label, icon).copyWith(
      suffixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.white38),
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
