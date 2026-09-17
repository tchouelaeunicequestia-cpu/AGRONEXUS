import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/platform_services.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _cniController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedRole = 'FARMER';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isLocationCaptured = false;
  bool _isFaceScanned = false;
  double? _lat;
  double? _lon;
  final String _locationName = 'Centre Region, Yaoundé';

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Map<String, dynamic>> _roles = [
    {
      'value': 'FARMER',
      'label': 'Farmer',
      'desc': 'Producer / Yield Host',
      'icon': Icons.agriculture_rounded,
    },
    {
      'value': 'BUYER',
      'label': 'Buyer',
      'desc': 'Off-taker / Wholesale',
      'icon': Icons.shopping_bag_outlined,
    },
    {
      'value': 'TRANSPORTER',
      'label': 'Transporter',
      'desc': 'Fleet & Cold-Chain',
      'icon': Icons.local_shipping_outlined,
    },
    {
      'value': 'AGRONOMIST',
      'label': 'Agronomist',
      'desc': 'Soil & Crop Auditor',
      'icon': Icons.psychology_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _cniController.dispose();
    _phoneController.dispose();
    _animController.dispose();
    super.dispose();
  }

  double get _completionProgress {
    double progress = 0.33;
    if (_isFaceScanned) progress += 0.34;
    if (_nameController.text.isNotEmpty && _emailController.text.isNotEmpty) progress += 0.33;
    return progress > 1.0 ? 1.0 : progress;
  }

  Future<void> _handleBiometricScan() async {
    bool isScanning = false;
    bool scanComplete = false;
    String statusMessage = 'Position your face inside the biometric verification frame.';

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void performScan() async {
              setDialogState(() {
                isScanning = true;
                statusMessage = 'Analyzing facial geometry & sensor hash...';
              });
              try {
                final identityService = IdentityServiceFactory.getService();
                bool verified = await identityService.verifyFaceOrBiometric();
                if (verified) {
                  setDialogState(() {
                    isScanning = false;
                    scanComplete = true;
                    statusMessage = 'Biometric identity verified successfully!';
                  });
                } else {
                  throw Exception('Biometric identity match failed.');
                }
              } catch (e) {
                setDialogState(() {
                  isScanning = false;
                  scanComplete = false;
                  statusMessage = e.toString().replaceAll("Exception: ", "");
                });
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              title: const Row(
                children: [
                  Icon(Icons.face_retouching_natural_rounded, color: Color(0xFF006c49)),
                  SizedBox(width: 12),
                  Text(
                    'Live Face Scan Verification',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0b1f14)),
                  ),
                ],
              ),
              content: SizedBox(
                width: 380,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        statusMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: scanComplete ? const Color(0xFF16a34a) : const Color(0xFF404942),
                          fontWeight: scanComplete ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        height: 160,
                        width: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF003820),
                          border: Border.all(
                            color: scanComplete
                                ? const Color(0xFF16a34a)
                                : isScanning
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFF6cf8bb),
                            width: 3,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (isScanning)
                              const SizedBox(
                                width: 140,
                                height: 140,
                                child: CircularProgressIndicator(color: Color(0xFF6cf8bb), strokeWidth: 3),
                              )
                            else if (scanComplete)
                              const Icon(Icons.check_circle_outline_rounded, color: Colors.greenAccent, size: 72)
                            else
                              const Icon(Icons.face_rounded, color: Color(0xFF81c784), size: 72),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (!scanComplete && !isScanning)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF003820),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: performScan,
                          icon: const Icon(Icons.camera_front_rounded),
                          label: const Text('Initiate Biometric Scan'),
                        ),
                      if (scanComplete)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16a34a).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_rounded, color: Color(0xFF16a34a), size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Identity Authenticated',
                                style: TextStyle(color: Color(0xFF16a34a), fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF404942))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006c49),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: !scanComplete
                      ? null
                      : () {
                          setState(() => _isFaceScanned = true);
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Live Face Scan Identity Confirmed!'),
                              backgroundColor: Color(0xFF006c49),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                  child: const Text('Save Verification'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isFaceScanned) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete the Live Face Scan verification first.'),
          backgroundColor: Color(0xFFba1a1a),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (!_isLocationCaptured) {
        try {
          final locService = LocationServiceFactory.getService();
          final pos = await locService.getCurrentLocation();
          _lat = pos.latitude;
          _lon = pos.longitude;
          _isLocationCaptured = true;
        } catch (_) {
          _lat = 3.8480;
          _lon = 11.5021;
        }
      }

      await ApiService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        role: _selectedRole,
        latitude: _lat,
        longitude: _lon,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric Enrollment Complete & Registered on Ledger!'),
            backgroundColor: Color(0xFF006c49),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration Error: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: const Color(0xFFba1a1a),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentProgress = _completionProgress;

    return Scaffold(
      backgroundColor: const Color(0xFFe9ffed),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: const Color(0xFFe9ffed).withValues(alpha: 0.85),
                elevation: 0,
                toolbarHeight: 64,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF003820)),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Back to Login',
                ),
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
                        Text('Escrow And Orders', style: TextStyle(color: Color(0xFF404942), fontSize: 11)),
                      ],
                    ),
                  ],
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFd6eedc),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(color: Color(0xFF006c49), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _selectedRole.toLowerCase().capitalize(),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF005236)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Padding(
                    padding: EdgeInsets.only(right: 16.0),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(0xFF003820),
                      child: Icon(Icons.person, size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFe1fae7),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Biometric Identity & Role',
                                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF003820)),
                                      ),
                                      Text(
                                        '${(currentProgress * 100).toInt()}%',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF006c49)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: TweenAnimationBuilder<double>(
                                      tween: Tween<double>(begin: 0, end: currentProgress),
                                      duration: const Duration(milliseconds: 400),
                                      builder: (context, value, _) => LinearProgressIndicator(
                                        value: value,
                                        backgroundColor: const Color(0xFFd0e8d6),
                                        color: const Color(0xFF006c49),
                                        minHeight: 8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Assigned Ecosystem Role',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF003820)),
                                  ),
                                  const SizedBox(height: 16),
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 2.2,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                    ),
                                    itemCount: _roles.length,
                                    itemBuilder: (context, index) {
                                      final role = _roles[index];
                                      final isSelected = _selectedRole == role['value'];
                                      return InkWell(
                                        onTap: () => setState(() => _selectedRole = role['value']),
                                        borderRadius: BorderRadius.circular(12),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: isSelected ? const Color(0xFF003820) : const Color(0xFFe1fae7),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isSelected ? const Color(0xFF003820) : const Color(0xFFc0c9c0),
                                              width: isSelected ? 1.5 : 1,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Icon(role['icon'],
                                                      color: isSelected
                                                          ? const Color(0xFF6cf8bb)
                                                          : const Color(0xFF404942),
                                                      size: 20),
                                                  Icon(
                                                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                                                    color: isSelected ? const Color(0xFF6cf8bb) : const Color(0xFFc0c9c0),
                                                    size: 16,
                                                  ),
                                                ],
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    role['label'],
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                      color: isSelected ? Colors.white : const Color(0xFF0b1f14),
                                                    ),
                                                  ),
                                                  Text(
                                                    role['desc'],
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: isSelected ? const Color(0xFF95d4ac) : const Color(0xFF404942),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10),
                                ],
                              ),
                              child: Column(
                                children: [
                                  const Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Live Face Scan Telemetry',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF003820)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Center(
                                    child: Container(
                                      height: 180,
                                      width: 180,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF003820),
                                        border: Border.all(
                                          color: _isFaceScanned ? const Color(0xFF16a34a) : const Color(0xFF6cf8bb),
                                          width: 3,
                                        ),
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          const Icon(Icons.face_rounded, size: 80, color: Color(0xFF81c784)),
                                          if (_isFaceScanned)
                                            Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.black.withValues(alpha: 0.4),
                                              ),
                                              child: const Center(
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.verified_rounded, color: Colors.greenAccent, size: 40),
                                                    Text('Verified', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(double.infinity, 48),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      side: const BorderSide(color: Color(0xFF003820)),
                                    ),
                                    onPressed: _handleBiometricScan,
                                    icon: Icon(
                                      _isFaceScanned ? Icons.check_circle : Icons.camera_front_rounded,
                                      color: _isFaceScanned ? const Color(0xFF16a34a) : const Color(0xFF003820),
                                    ),
                                    label: Text(
                                      _isFaceScanned ? 'Biometric Scan Verified ✓' : 'Initiate Live Face Scan',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _isFaceScanned ? const Color(0xFF16a34a) : const Color(0xFF003820),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Identity Profile Record',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF003820)),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _nameController,
                                    onChanged: (_) => setState(() {}),
                                    decoration: const InputDecoration(
                                      labelText: 'Full Legal Name',
                                      hintText: 'Enter your full name',
                                      prefixIcon: Icon(Icons.person_outline),
                                    ),
                                    validator: (v) => v!.isEmpty ? 'Required' : null,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _cniController,
                                          decoration: const InputDecoration(
                                            labelText: 'National ID (CNI)',
                                            hintText: 'e.g., LT-2024-8912',
                                            prefixIcon: Icon(Icons.badge_outlined),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _phoneController,
                                          decoration: const InputDecoration(
                                            labelText: 'Verified Phone',
                                            hintText: '+237...',
                                            prefixIcon: Icon(Icons.phone_outlined),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _emailController,
                                    onChanged: (_) => setState(() {}),
                                    decoration: const InputDecoration(
                                      labelText: 'Official Hub Email',
                                      hintText: 'user@agronexus.io',
                                      prefixIcon: Icon(Icons.email_outlined),
                                    ),
                                    validator: (v) => v!.isEmpty ? 'Required' : null,
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      hintText: 'Min 6 characters',
                                      prefixIcon: const Icon(Icons.lock_outline),
                                      suffixIcon: IconButton(
                                        icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                      ),
                                    ),
                                    validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF003820),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                onPressed: _isLoading ? null : _submitRegister,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.fingerprint, color: Colors.white),
                                          SizedBox(width: 8),
                                          Text(
                                            'Complete Biometric Verification & Enroll',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Back to Login Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Already have an account?', style: TextStyle(color: Color(0xFF404942), fontSize: 13)),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      color: Color(0xFF003820),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}