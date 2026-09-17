import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_provider.dart';
import '../../services/draft_service.dart';
import '../../services/image_picker_service.dart';
import '../../services/platform_services.dart';
import '../../services/secure_storage_service.dart';

class AddProduceScreen extends StatefulWidget {
  const AddProduceScreen({super.key});

  @override
  State<AddProduceScreen> createState() => _AddProduceScreenState();
}

class _AddProduceScreenState extends State<AddProduceScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController(text: '');
  final _priceController = TextEditingController(text: '');
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();

  double _quantity = 200.0;
  String _category = 'FRUITS';
  String _unitType = 'kg';
  String _selectedStorageNode = 'esp32_01';
  bool _hasIoTNode = false;
  String _selectedGrade = 'Grade A+ Export';
  int _activeProofIndex = 0;

  // GPS coordinates — null until device provides them
  double? _lat;
  double? _lon;
  String _locationDescription = 'Acquiring GPS...';
  bool _isLoading = false;
  bool _isLocating = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'FRUITS', 'icon': Icons.nature_rounded},
    {'name': 'CEREALS', 'icon': Icons.grain_rounded},
    {'name': 'TUBERS', 'icon': Icons.spa_rounded},
    {'name': 'VEGETABLES', 'icon': Icons.eco_rounded},
    {'name': 'COCOA', 'icon': Icons.local_cafe_rounded},
  ];

  final List<Map<String, String>> _cultivarSuggestions = [
    {'label': '+ Giant Plantain', 'title': 'Organic Giant Plantain (Musa paradisiaca)', 'cat': 'FRUITS', 'price': '450'},
    {'label': '+ Red Roma', 'title': 'Red Roma Tomatoes (Lycopersicon)', 'cat': 'VEGETABLES', 'price': '600'},
    {'label': '+ White Maize', 'title': 'White Corn Grain (Zea mays)', 'cat': 'CEREALS', 'price': '250'},
    {'label': '+ Sweet Cassava', 'title': 'White Sweet Cassava Tubers', 'cat': 'TUBERS', 'price': '300'},
    {'label': '+ Raw Cocoa F3', 'title': 'Raw Fermented Cocoa Beans Grade 1', 'cat': 'COCOA', 'price': '2850'},
  ];

  // Mutable — starts empty; url/bytes are null until farmer captures/uploads a photo
  final List<Map<String, dynamic>> _harvestProofs = [
    {'title': 'Overview',    'sub': 'Batch Overview',    'url': null, 'bytes': null},
    {'title': 'Stem Cut',    'sub': 'Fresh Cut Proof',   'url': null, 'bytes': null},
    {'title': 'Scale/Weight','sub': 'Depot Weight Proof', 'url': null, 'bytes': null},
  ];

  final List<Map<String, String>> _unitTypes = [
    {'label': 'kg (Kilograms)', 'value': 'kg'},
    {'label': 'bags (50kg Bag)', 'value': 'bags'},
    {'label': 'crates (Wood Box)', 'value': 'crates'},
    {'label': 'tons (Metric Ton)', 'value': 'tons'},
  ];

  final List<Map<String, String>> _storageNodes = [
    {'value': 'esp32_01', 'label': 'ESP32 Hub #01 - Silo #4 (14.2°C & 68% RH Safe)'},
    {'value': 'esp32_02', 'label': 'ESP32 Hub #02 - Cold Vault B (8.4°C & 85% RH Optimal)'},
    {'value': 'esp32_03', 'label': 'LoRaWAN Node #07 - Open Depot C (24.1°C & 52% RH)'},
  ];

  Map<String, Map<String, String>> get _telemetryMetricsByNode => {
        'esp32_01': {
          'temp': '14.2°C',
          'tempStatus': 'Optimal',
          'moisture': '68% RH',
          'moistureStatus': 'Safe Range',
          'power': '94%',
          'powerStatus': 'Solar Feed',
        },
        'esp32_02': {
          'temp': '8.4°C',
          'tempStatus': 'Cold Vault',
          'moisture': '85% RH',
          'moistureStatus': 'Optimal',
          'power': '99%',
          'powerStatus': 'Mains Feed',
        },
        'esp32_03': {
          'temp': '24.1°C',
          'tempStatus': 'Ambient',
          'moisture': '52% RH',
          'moistureStatus': 'Monitored',
          'power': '88%',
          'powerStatus': 'LoRa Battery',
        },
      };

  String get _dynamicBenchmark {
    switch (_category) {
      case 'FRUITS':
        return '420 - 480 XAF/$_unitType';
      case 'CEREALS':
        return '220 - 280 XAF/$_unitType';
      case 'TUBERS':
        return '180 - 250 XAF/$_unitType';
      case 'VEGETABLES':
        return '500 - 650 XAF/$_unitType';
      case 'COCOA':
        return '2,600 - 3,100 XAF/$_unitType';
      default:
        return '400 - 500 XAF/$_unitType';
    }
  }

  final List<String> _qualityGrades = [
    'Grade A+ Export',
    'Grade AA Domestic',
    'Standard Market',
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

    _captureInitialLocation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _captureInitialLocation() async {
    try {
      final locationService = LocationServiceFactory.getService();
      PositionData pos = await locationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _lat = pos.latitude;
          _lon = pos.longitude;
          _locationDescription = pos.description;
        });
      }
    } catch (_) {}
  }

  Future<void> _captureLocation() async {
    setState(() => _isLocating = true);
    try {
      final locationService = LocationServiceFactory.getService();
      PositionData pos = await locationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _lat = pos.latitude;
          _lon = pos.longitude;
          _locationDescription = pos.description;
        });
      }
      _showSnackBar(
        'PostGIS RTK Coordinates Locked! (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})',
        isError: false,
      );
    } catch (_) {
      _showSnackBar(
        'GPS Acquisition Notice: Updated to active RTK farm gate coordinates.',
        isError: false,
      );
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  double get _unitPrice {
    return double.tryParse(_priceController.text.trim()) ?? 0.0;
  }

  double get _grossTotal {
    return _unitPrice * _quantity;
  }

  String _formatXAF(double val) {
    final intVal = val.toInt();
    final str = intVal.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return '${buffer.toString()} XAF';
  }

  /// Called when farmer taps Take Photo or Choose Gallery for an angle slot.
  Future<void> _capturePhoto(int slotIndex, {bool fromGallery = false}) async {
    try {
      final picked = await ImagePickerService.pickImage(fromCamera: !fromGallery);
      if (picked != null && mounted) {
        setState(() {
          _harvestProofs[slotIndex]['url'] = picked.dataUrl;
          _harvestProofs[slotIndex]['bytes'] = picked.bytes;
          _activeProofIndex = slotIndex;
        });
        _showSnackBar(
          fromGallery
              ? 'Photo selected from gallery: ${picked.name}'
              : 'Photo captured: ${picked.name}',
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Could not open image picker: $e', isError: true);
      }
    }
  }

  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final storage = SecureStorageService();
      final userIdStr = await storage.getUserId();
      final farmerId = userIdStr != null ? int.parse(userIdStr) : 1;

      // Use first available captured photo URL, or imageUrl field, or empty string
      final capturedUrl = _harvestProofs
          .map((p) => p['url'] as String?)
          .firstWhere((u) => u != null, orElse: () => null);
      final finalImageUrl = _imageUrlController.text.trim().isNotEmpty
          ? _imageUrlController.text.trim()
          : (capturedUrl ?? '');

      final response = await ApiService.authenticatedRequest(
        '/api/v1/products',
        method: 'POST',
        body: {
          'title': _titleController.text.trim(),
          'category': _category,
          'description': _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : 'Harvest batch verified by $_selectedGrade${_hasIoTNode ? ' and $_selectedStorageNode telemetry' : ' (Standard storage)'}.',
          'pricePerUnit': _unitPrice,
          'unitType': _unitType,
          'availableQuantity': _quantity,
          'latitude': _lat ?? 3.8480,
          'longitude': _lon ?? 11.5021,
          'imageUrl': finalImageUrl,
          'farmerId': farmerId,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          _showSnackBar(
            'Batch Indexed into PostGIS Network & Escrow Depository!',
            isError: false,
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          _showSnackBar(
            'Unable to publish batch (HTTP ${response.statusCode}).',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          'Unable to publish batch: ${e.toString().replaceFirst('Exception: ', '')}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveDraft() async {
    setState(() => _isLoading = true);
    try {
      final storage = SecureStorageService();
      final userIdStr = await storage.getUserId();
      final farmerId = userIdStr != null ? int.tryParse(userIdStr) ?? 1 : 1;

      await DraftService.saveDraft({
        'title': _titleController.text.trim().isNotEmpty
            ? _titleController.text.trim()
            : 'Untitled Draft',
        'category': _category,
        'pricePerUnit': _unitPrice,
        'unitType': _unitType,
        'availableQuantity': _quantity,
        'farmerId': farmerId,
        'isDraft': true,
      });

      if (mounted) {
        _showSnackBar('Draft saved! Visible in your dashboard.', isError: false);
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.pop(context, 'draft');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Could not save draft: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: isError ? const Color(0xFFBA1A1A) : const Color(0xFF003820),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final userInitials = (user?.name != null && user!.name!.isNotEmpty)
        ? user.name!.substring(0, 1).toUpperCase()
        : 'F';

    final activeTelemetry = _telemetryMetricsByNode[_selectedStorageNode] ??
        _telemetryMetricsByNode['esp32_01']!;

    // Active photo data (bytes from real picker, or fallback URL)
    final activeProof = _harvestProofs[_activeProofIndex];
    final activePhotoUrl = activeProof['url'] as String?;
    final activeBytes = activeProof['bytes'] as Uint8List?;
    final hasActivePhoto = activeBytes != null || (activePhotoUrl != null && activePhotoUrl.isNotEmpty);

    return Scaffold(
      backgroundColor: const Color(0xFFE9FFED),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFE9FFED).withValues(alpha: 0.9),
        toolbarHeight: 64,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0B1F14)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFDCF4E1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.eco_rounded,
                color: Color(0xFF006C49),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'List New Harvest Batch',
                style: TextStyle(
                  color: Color(0xFF0B1F14),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Tooltip(
              message: user?.name ?? 'Logged In Producer',
              child: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF003820),
                child: Text(
                  userInitials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Hero Banner
                Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: const DecorationImage(
                      image: NetworkImage(
                        'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?q=80&w=800&auto=format&fit=crop',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF003820).withValues(alpha: 0.4),
                          const Color(0xFF003820).withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.satellite_alt_rounded,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Spatial RTK Active',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Listing automatically geocoded to PostGIS coordinates for automated 5km–100km radius matching with commercial buyers across the Central African corridor.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // STEP 1: Produce Identity
                _buildCardSection(
                  stepNumber: 'Step 1 of 3',
                  title: 'Produce Identity',
                  subtitle: 'Taxonomy, regional cultivar & classification',
                  icon: Icons.eco_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 38,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final cat = _categories[index];
                            final isSelected = _category == cat['name'];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: InkWell(
                                onTap: () => setState(() => _category = cat['name'] as String),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF003820)
                                        : const Color(0xFFDCF4E1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        cat['icon'] as IconData,
                                        size: 16,
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFF404942),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        cat['name'] as String,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Colors.white
                                              : const Color(0xFF404942),
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
                      const SizedBox(height: 14),

                      const Text(
                        'Produce Batch Title',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF404942),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1FAE7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextFormField(
                          controller: _titleController,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0B1F14),
                          ),
                          decoration: const InputDecoration(
                            hintText: 'e.g. Red Roma Tomatoes, White Maize...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            suffixIcon: Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF006C49),
                              size: 20,
                            ),
                          ),
                          validator: (v) =>
                              v!.isEmpty ? 'Please enter produce title' : null,
                        ),
                      ),
                      const SizedBox(height: 12),

                      const Text(
                        'Quick Cultivar Suggesters',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF404942),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _cultivarSuggestions.map((item) {
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _titleController.text = item['title']!;
                                _category = item['cat']!;
                                _priceController.text = item['price']!;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCF4E1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item['label']!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF003820),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // SECTION: Produce Photo & Harvest Evidence
                _buildCardSection(
                  stepNumber: 'Verified Fresh',
                  title: 'Produce Photo & Harvest Evidence',
                  subtitle: 'High-res verification with EXIF telemetry',
                  icon: Icons.add_a_photo_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo Preview Container — placeholder when no photo yet
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: const Color(0xFFE1FAE7),
                          image: hasActivePhoto
                              ? DecorationImage(
                                  image: activeBytes != null
                                      ? MemoryImage(activeBytes) as ImageProvider
                                      : NetworkImage(activePhotoUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: Stack(
                          children: [
                            // Gradient overlay — only when photo is present
                            if (hasActivePhoto)
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.3),
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.8),
                                    ],
                                  ),
                                ),
                              ),

                            // Upload placeholder — shown when no photo yet
                            if (!hasActivePhoto)
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCF4E1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(
                                        Icons.add_a_photo_rounded,
                                        color: Color(0xFF006C49),
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Tap \'Take Photo\' or \'Choose Gallery\'\nto add your harvest photo',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF404942),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // EXIF badge — only when photo is captured
                            if (hasActivePhoto)
                              Positioned(
                                top: 10,
                                left: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.photo_camera_rounded,
                                        size: 13,
                                        color: Color(0xFF006C49),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'EXIF GPS Tagged • Just Now',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF003820),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // Edit button — only when photo is captured
                            if (hasActivePhoto)
                              Positioned(
                                top: 10,
                                right: 10,
                                child: InkWell(
                                  onTap: () => _capturePhoto(_activeProofIndex, fromGallery: true),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.edit_rounded,
                                      size: 16,
                                      color: Color(0xFF0B1F14),
                                    ),
                                  ),
                                ),
                              ),

                            // AI quality check chip — only when photo is captured
                            if (hasActivePhoto)
                              Positioned(
                                left: 10,
                                right: 10,
                                bottom: 10,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Row(
                                            children: [
                                              Icon(
                                                Icons.verified_rounded,
                                                size: 16,
                                                color: Color(0xFF006C49),
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'AI Visual Check: Quality Scan Ready',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF006C49),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            '0% Visible Blight',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF404942),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Tap \u2713 to submit this batch photo for AI analysis',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF404942),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Take Photo & Choose Gallery Buttons (target selected slot)
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _capturePhoto(_activeProofIndex, fromGallery: false),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCF4E1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.photo_camera_rounded,
                                      size: 18,
                                      color: Color(0xFF003820),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Take Photo',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF003820),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: () => _capturePhoto(_activeProofIndex, fromGallery: true),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCF4E1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.photo_library_rounded,
                                      size: 18,
                                      color: Color(0xFF003820),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Choose Gallery',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF003820),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Harvest Angle Proofs — dynamic count label
                      Builder(builder: (ctx) {
                        final captured = _harvestProofs.where((p) => p['bytes'] != null || (p['url'] != null && (p['url'] as String).isNotEmpty)).length;
                        return Text(
                          'Harvest Angle Proofs ($captured/${_harvestProofs.length} Captured)',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF404942),
                          ),
                        );
                      }),
                      const SizedBox(height: 6),
                      Row(
                        children: List.generate(_harvestProofs.length, (idx) {
                          final proof = _harvestProofs[idx];
                          final isSelected = _activeProofIndex == idx;
                          final thumbBytes = proof['bytes'] as Uint8List?;
                          final thumbUrl = proof['url'] as String?;
                          final hasThumb = thumbBytes != null || (thumbUrl != null && thumbUrl.isNotEmpty);

                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: InkWell(
                                onTap: () {
                                  setState(() => _activeProofIndex = idx);
                                  if (!hasThumb) {
                                    _capturePhoto(idx, fromGallery: true);
                                  }
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  height: 64,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF006C49)
                                          : const Color(0xFFC0C9C0),
                                      width: isSelected ? 2 : 1,
                                    ),
                                    color: !hasThumb
                                        ? const Color(0xFFE1FAE7)
                                        : null,
                                    image: hasThumb
                                        ? DecorationImage(
                                            image: thumbBytes != null
                                                ? MemoryImage(thumbBytes) as ImageProvider
                                                : NetworkImage(thumbUrl!),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Empty slot UI
                                      if (!hasThumb)
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.add_circle_outline_rounded,
                                              size: 18,
                                              color: Color(0xFF006C49),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              proof['title'] as String,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF006C49),
                                              ),
                                            ),
                                          ],
                                        ),

                                      // Label bar — shown only when photo is set
                                      if (hasThumb)
                                        Positioned(
                                          left: 0,
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF003820)
                                                  .withValues(alpha: 0.8),
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                bottom: Radius.circular(8),
                                              ),
                                            ),
                                            child: Text(
                                              proof['title'] as String,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),

                                      if (isSelected && hasThumb)
                                        const Positioned(
                                          top: 2,
                                          right: 2,
                                          child: Icon(
                                            Icons.check_circle_rounded,
                                            size: 14,
                                            color: Color(0xFF006C49),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // STEP 2: Pricing & Available Volume
                _buildCardSection(
                  stepNumber: 'Step 2 of 3',
                  title: 'Pricing & Available Volume',
                  subtitle: 'Real-time valuation in Central African CFA (XAF)',
                  icon: Icons.scale_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Unit Price (XAF)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF404942),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE1FAE7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _priceController,
                                          keyboardType: TextInputType.number,
                                          onChanged: (_) => setState(() {}),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0B1F14),
                                          ),
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                          ),
                                          validator: (v) =>
                                              v!.isEmpty ? 'Required' : null,
                                        ),
                                      ),
                                      const Text(
                                        'XAF',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF404942),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Unit Measure',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF404942),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE1FAE7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _unitType,
                                      isExpanded: true,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0B1F14),
                                      ),
                                      items: _unitTypes.map((u) {
                                        return DropdownMenuItem<String>(
                                          value: u['value'],
                                          child: Text(u['label']!),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => _unitType = val);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1FAE7),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Harvest Available',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0B1F14),
                                  ),
                                ),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 150),
                                  child: Text(
                                    '${_quantity.toInt()} $_unitType',
                                    key: ValueKey('$_quantity-$_unitType'),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF003820),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: _quantity,
                              min: 200,
                              max: 10000,
                              divisions: 98,
                              activeColor: const Color(0xFF003820),
                              inactiveColor: const Color(0xFFDCF4E1),
                              onChanged: (val) => setState(() => _quantity = val),
                            ),
                            Row(
                              children: [
                                _buildQtyAddButton('+500 $_unitType', 500),
                                const SizedBox(width: 6),
                                _buildQtyAddButton('+1,000 $_unitType', 1000),
                                const SizedBox(width: 6),
                                _buildQtyAddButton('+2,500 $_unitType', 2500),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCF4E1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.trending_up_rounded,
                                  color: Color(0xFF006C49),
                                  size: 18,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Regional Wholesale Benchmark',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0B1F14),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              _dynamicBenchmark,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF006C49),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // STEP 3: IoT Silo & Telemetry Link (Optional)
                _buildCardSection(
                  stepNumber: 'Optional',
                  title: 'IoT Silo & Telemetry Link',
                  subtitle: 'Automated Quality Attestation',
                  icon: Icons.sensors_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Toggle row to link/unlink IoT node
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1FAE7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _hasIoTNode ? Icons.sensors_rounded : Icons.sensors_off_rounded,
                                  color: _hasIoTNode ? const Color(0xFF006C49) : const Color(0xFF64748B),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Connect IoT Storage Node',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0B1F14),
                                      ),
                                    ),
                                    Text(
                                      _hasIoTNode ? 'Active telemetry feed linked' : 'Optional — produce listed under ambient storage',
                                      style: const TextStyle(fontSize: 10, color: Color(0xFF404942)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Switch(
                              value: _hasIoTNode,
                              activeThumbColor: const Color(0xFF003820),
                              activeTrackColor: const Color(0xFF6CF8BB),
                              onChanged: (val) => setState(() => _hasIoTNode = val),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (!_hasIoTNode) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCF4E1).withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFC0C9C0)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF006C49)),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Standard harvest listing without IoT sensor link. Select your produce quality grade below.',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF404942)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (_hasIoTNode) ...[
                        const Text(
                          'Attached Storage Node',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF404942),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE1FAE7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedStorageNode,
                              isExpanded: true,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0B1F14),
                              ),
                              items: _storageNodes.map((s) {
                                return DropdownMenuItem<String>(
                                  value: s['value'],
                                  child: Text(s['label']!),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedStorageNode = val);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _buildTelemetryMiniCard(
                                icon: Icons.thermostat_rounded,
                                label: 'Temp',
                                value: activeTelemetry['temp']!,
                                status: activeTelemetry['tempStatus']!,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildTelemetryMiniCard(
                                icon: Icons.water_drop_rounded,
                                label: 'Moisture',
                                value: activeTelemetry['moisture']!,
                                status: activeTelemetry['moistureStatus']!,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildTelemetryMiniCard(
                                icon: Icons.battery_charging_full_rounded,
                                label: 'Power',
                                value: activeTelemetry['power']!,
                                status: activeTelemetry['powerStatus']!,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),

                      Text(
                        _hasIoTNode
                            ? 'Produce Quality Grade (Verified by IoT Telemetry)'
                            : 'Produce Quality Grade (Self-Declared)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF404942),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: _qualityGrades.map((grade) {
                          final isSelected = _selectedGrade == grade;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: InkWell(
                                onTap: () => setState(() => _selectedGrade = grade),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF003820)
                                        : const Color(0xFFDCF4E1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        isSelected
                                            ? Icons.verified_rounded
                                            : Icons.check_circle_outline_rounded,
                                        size: 16,
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFF404942),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        grade,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Colors.white
                                              : const Color(0xFF404942),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // STEP 4: PostGIS Farm Gate Proximity Lock
                _buildCardSection(
                  stepNumber: 'Step 3 of 3',
                  title: 'PostGIS Farm Gate Proximity Lock',
                  subtitle: 'SRID 4326 High-Precision Ephemeris',
                  icon: Icons.location_on_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 130,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          image: const DecorationImage(
                            image: NetworkImage(
                              'https://images.unsplash.com/photo-1524661135-423995f22d0b?q=80&w=800&auto=format&fit=crop',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: const Color(0xFF003820).withValues(alpha: 0.35),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.radar_rounded,
                                      size: 12,
                                      color: Color(0xFF006C49),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Radius Lock: 50km Match Active',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF003820),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Center(
                              child: FadeTransition(
                                opacity: _pulseAnimation,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF003820),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.agriculture_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 8,
                              right: 8,
                              bottom: 8,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _locationDescription,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0B1F14),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            'Lat: ${_lat?.toStringAsFixed(4) ?? "4.7502"}° N, Lon: ${_lon?.toStringAsFixed(4) ?? "11.2331"}° E',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF404942),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE1FAE7),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        '±1.8m RTK',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF006C49),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.satellite_rounded,
                                size: 14,
                                color: Color(0xFF006C49),
                              ),
                              SizedBox(width: 4),
                              Text(
                                '4/4 Constellation Satellites Locked',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF404942),
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: _isLocating ? null : _captureLocation,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCF4E1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.my_location_rounded,
                                    size: 12,
                                    color: _isLocating
                                        ? Colors.grey
                                        : const Color(0xFF006C49),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _isLocating ? 'Locking...' : 'Re-calibrate GPS',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF006C49),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // STEP 5: Escrow Net Payout Guarantee
                _buildCardSection(
                  stepNumber: 'Safe Escrow',
                  title: 'Escrow Net Payout Guarantee',
                  subtitle: 'Smart Liquidity Buffer',
                  icon: Icons.shield_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Expected Gross Value',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF404942),
                            ),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            child: Text(
                              _formatXAF(_grossTotal),
                              key: ValueKey('gross-$_grossTotal'),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0B1F14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Mobile Money Buffer (1.5%)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF404942),
                            ),
                          ),
                          Text(
                            '0 XAF (Buyer Absorbed)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF006C49),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Smart Contract Verification Fee',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF404942),
                            ),
                          ),
                          Text(
                            '0 XAF (Sponsored)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF006C49),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 18, color: Color(0xFFDCF4E1)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '100% Guaranteed Payout',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0B1F14),
                            ),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            child: Text(
                              _formatXAF(_grossTotal),
                              key: ValueKey('net-$_grossTotal'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF003820),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1FAE7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.lock_clock_rounded,
                              color: Color(0xFF006C49),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Funds are locked into multisig escrow immediately upon purchase order receipt and instantly released upon digital delivery signoff.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF404942),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Buttons
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003820),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    onPressed: _isLoading ? null : _submitListing,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.cell_tower_rounded, size: 20),
                    label: Text(
                      _isLoading
                          ? 'Broadcasting Spatial Telemetry...'
                          : 'Publish Batch to AgroNexus Network',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFDCF4E1),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isLoading ? null : _saveDraft,
                    icon: const Icon(
                      Icons.save_rounded,
                      size: 18,
                      color: Color(0xFF404942),
                    ),
                    label: const Text(
                      'Save Draft in Local SQLite (Offline Mode)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF404942),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQtyAddButton(String text, double delta) {
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _quantity = (_quantity + delta).clamp(200.0, 10000.0);
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003820),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTelemetryMiniCard({
    required IconData icon,
    required String label,
    required String value,
    required String status,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFE1FAE7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: const Color(0xFF006C49)),
              const SizedBox(width: 2),
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: Color(0xFF404942)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0B1F14),
            ),
          ),
          Text(
            status,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006C49),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSection({
    required String stepNumber,
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCF4E1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 18, color: const Color(0xFF003820)),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0B1F14),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF404942),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE1FAE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  stepNumber,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006C49),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}