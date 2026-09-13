import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/platform_services.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedRole = 'FARMER';
  bool _isLoading = false;

  // Verification State Variables
  bool _isLocationCaptured = false;
  bool _isFaceScanned = false;
  double? _lat;
  double? _lon;
  String _locationName = 'Not Captured';

  final List<Map<String, dynamic>> _roles = [
    {'value': 'FARMER', 'label': 'Farmer', 'icon': Icons.agriculture, 'desc': 'List produce & track storage'},
    {'value': 'BUYER', 'label': 'Buyer', 'icon': Icons.shopping_cart, 'desc': 'Purchase via secure escrow'},
    {'value': 'TRANSPORTER', 'label': 'Transporter', 'icon': Icons.local_shipping, 'desc': 'Manage freight logistics'},
    {'value': 'AGRONOMIST', 'label': 'Agronomist', 'icon': Icons.eco, 'desc': 'Provide RAG AI guidance'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- STEP 3A: INTEGRATED LOCATION MODAL ---
  void _openLocationVerificationModal() {
    bool isFetching = false;
    double? tempLat = _lat;
    double? tempLon = _lon;
    String tempLocName = _locationName;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> fetchGPS() async {
              setDialogState(() => isFetching = true);
              try {
                // Call abstraction factory instead of direct plugin code
                final locationService = LocationServiceFactory.getService();
                PositionData positionData = await locationService.getCurrentLocation();

                tempLat = positionData.latitude;
                tempLon = positionData.longitude;
                tempLocName = positionData.description;
              } catch (e) {
                tempLocName = 'Error: ${e.toString().replaceAll("Exception: ", "")}';
              } finally {
                setDialogState(() => isFetching = false);
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.gps_fixed, color: Colors.green.shade700),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Geospatial PostGIS Lock',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 380,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Acquiring coordinates for spatial indexing (SRID: 4326).',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Latitude:', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(tempLat != null ? tempLat!.toStringAsFixed(6) : 'Not detected'),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Longitude:', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(tempLon != null ? tempLon!.toStringAsFixed(6) : 'Not detected'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Divider(),
                            const SizedBox(height: 4),
                            Text(
                              'Status: $tempLocName',
                              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (isFetching)
                        const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                      else
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 42),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: fetchGPS,
                          icon: const Icon(Icons.my_location, size: 18),
                          label: const Text('Get GPS Position'),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade800, foregroundColor: Colors.white),
                  onPressed: tempLat == null
                      ? null
                      : () {
                          setState(() {
                            _lat = tempLat;
                            _lon = tempLon;
                            _locationName = tempLocName;
                            _isLocationCaptured = true;
                          });
                          Navigator.pop(dialogContext);
                          _showSuccess('GPS Coordinates Confirmed!');
                        },
                  child: const Text('Confirm Location'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- STEP 3B: INTEGRATED BIOMETRIC MODAL ---
  void _openFaceScanModal() {
    bool isScanning = false;
    bool scanComplete = false;
    String statusMessage = 'Position your face inside the biometric frame.';

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void performBiometricScan() async {
              setDialogState(() {
                isScanning = true;
                statusMessage = 'Communicating with biometric sensor...';
              });

              try {
                // Call abstraction factory instead of direct plugin code
                final identityService = IdentityServiceFactory.getService();
                bool verified = await identityService.verifyFaceOrBiometric();

                if (verified) {
                  setDialogState(() {
                    isScanning = false;
                    scanComplete = true;
                    statusMessage = 'Biometric signature verified!';
                  });
                } else {
                  throw Exception('Biometric authentication failed.');
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.face_retouching_natural, color: Colors.green.shade700),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Live Face Scan Verification',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 360,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        statusMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: scanComplete ? Colors.green.shade800 : Colors.grey.shade700,
                          fontWeight: scanComplete ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        height: 160,
                        width: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade900,
                          border: Border.all(
                            color: scanComplete
                                ? Colors.greenAccent
                                : isScanning
                                    ? Colors.amber
                                    : Colors.green.shade700,
                            width: 3,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (isScanning)
                              const CircularProgressIndicator(color: Colors.amber, strokeWidth: 3)
                            else if (scanComplete)
                              const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 64)
                            else
                              Icon(Icons.face, color: Colors.green.shade300, size: 64),
                            if (isScanning)
                              const Positioned(
                                bottom: 12,
                                child: Text('Analyzing geometry...', style: TextStyle(color: Colors.white70, fontSize: 10)),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (!scanComplete && !isScanning)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: performBiometricScan,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Start Live Scan'),
                        ),
                      if (scanComplete)
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Identity Verified', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Close'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade800, foregroundColor: Colors.white),
                  onPressed: !scanComplete
                      ? null
                      : () {
                          setState(() {
                            _isFaceScanned = true;
                          });
                          Navigator.pop(dialogContext);
                          _showSuccess('Live Face Scan Verified!');
                        },
                  child: const Text('Save & Continue'),
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

    if (!_isLocationCaptured || !_isFaceScanned) {
      _showError('Please complete both GPS Location and Live Face Scan verifications.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        role: _selectedRole,
        latitude: _lat,
        longitude: _lon,
      );

      if (mounted) {
        _showSuccess('Account verified & created successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Server Error: ${e.toString().replaceAll("Exception: ", "")}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccess(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green.shade700));
  }

  void _showError(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;

          return Row(
            children: [
              if (isDesktop)
                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: const NetworkImage('https://images.unsplash.com/photo-1500937386664-56d1dfef3854?q=80&w=1920&auto=format&fit=crop'),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.55), BlendMode.darken),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(48.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.eco, size: 64, color: Colors.white),
                          const SizedBox(height: 24),
                          const Text('AgroNexus', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 16),
                          Text(
                            'An Integrated Agricultural Management\nand Information Platform.',
                            style: TextStyle(fontSize: 20, color: Colors.green.shade50, height: 1.5),
                          ),
                          const SizedBox(height: 48),
                          _buildFeatureItem(Icons.security, 'Secure Escrow Payments'),
                          _buildFeatureItem(Icons.map, 'Spatial Produce Discovery'),
                          _buildFeatureItem(Icons.memory, 'IoT Storage Telemetry'),
                          _buildFeatureItem(Icons.smart_toy, 'Domain-Guarded AI (FAO/USDA)'),
                        ],
                      ),
                    ),
                  ),
                ),
              Expanded(
                flex: 7,
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 48.0 : 24.0,
                      vertical: 32.0,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 550),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Create your account', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.grey.shade900)),
                            const SizedBox(height: 8),
                            Text('Join the AgroNexus multi-role ecosystem.', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                            const SizedBox(height: 32),
                            Text('Select Your Role', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                            const SizedBox(height: 12),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: isDesktop ? 2.3 : 1.9,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                              itemCount: _roles.length,
                              itemBuilder: (context, index) {
                                final role = _roles[index];
                                final isSelected = _selectedRole == role['value'];
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedRole = role['value']),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.green.shade50 : Colors.white,
                                      border: Border.all(color: isSelected ? Colors.green.shade700 : Colors.grey.shade300, width: 2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: Row(
                                      children: [
                                        Icon(role['icon'], color: isSelected ? Colors.green.shade700 : Colors.grey.shade500, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                role['label'],
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: isSelected ? Colors.green.shade900 : Colors.grey.shade800,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                role['desc'],
                                                style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _nameController,
                              decoration: _inputDecoration('Full Legal Name', Icons.person_outline),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: _inputDecoration('Email Address', Icons.email_outlined),
                              validator: (v) => v!.isEmpty || !v.contains('@') ? 'Valid email required' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: _inputDecoration('Password', Icons.lock_outline),
                              validator: (v) => v!.length < 6 ? 'Min 6 chars' : null,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _openLocationVerificationModal,
                                    icon: Icon(
                                      _isLocationCaptured ? Icons.check_circle : Icons.gps_fixed,
                                      color: _isLocationCaptured ? Colors.green.shade700 : Colors.blueGrey,
                                      size: 18,
                                    ),
                                    label: Text(
                                      _isLocationCaptured ? 'GPS Verified' : 'Verify Location',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: _isLocationCaptured ? FontWeight.bold : FontWeight.normal,
                                        color: _isLocationCaptured ? Colors.green.shade800 : null,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                                      side: BorderSide(
                                        color: _isLocationCaptured ? Colors.green.shade700 : Colors.grey.shade300,
                                        width: _isLocationCaptured ? 2 : 1,
                                      ),
                                      backgroundColor: _isLocationCaptured ? Colors.green.shade50 : null,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _openFaceScanModal,
                                    icon: Icon(
                                      _isFaceScanned ? Icons.check_circle : Icons.face,
                                      color: _isFaceScanned ? Colors.green.shade700 : Colors.blueGrey,
                                      size: 18,
                                    ),
                                    label: Text(
                                      _isFaceScanned ? 'Face Verified' : 'Live Face Scan',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: _isFaceScanned ? FontWeight.bold : FontWeight.normal,
                                        color: _isFaceScanned ? Colors.green.shade800 : null,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                                      side: BorderSide(
                                        color: _isFaceScanned ? Colors.green.shade700 : Colors.grey.shade300,
                                        width: _isFaceScanned ? 2 : 1,
                                      ),
                                      backgroundColor: _isFaceScanned ? Colors.green.shade50 : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade800,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: _isLoading ? null : _submitRegister,
                                child: _isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text('Complete Registration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Already have an account? Sign In', style: TextStyle(color: Colors.green.shade800)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.green.shade300, size: 24),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16))),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey.shade600),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.green.shade700, width: 2)),
    );
  }
}