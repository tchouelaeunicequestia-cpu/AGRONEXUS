import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/platform_services.dart';
import '../../services/secure_storage_service.dart';

class AddProduceScreen extends StatefulWidget {
  const AddProduceScreen({super.key});

  @override
  State<AddProduceScreen> createState() => _AddProduceScreenState();
}

class _AddProduceScreenState extends State<AddProduceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _category = 'CEREALS';
  String _unitType = 'kg';
  double? _lat;
  double? _lon;
  bool _isLoading = false;
  bool _locationCaptured = false;

  final List<String> _categories = ['CEREALS', 'TUBERS', 'VEGETABLES', 'FRUITS', 'LEGUMES'];

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _captureLocation() async {
    try {
      final locationService = LocationServiceFactory.getService();
      PositionData pos = await locationService.getCurrentLocation();
      setState(() {
        _lat = pos.latitude;
        _lon = pos.longitude;
        _locationCaptured = true;
      });
      _showSnackBar('Farm gate coordinates locked! (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})');
    } catch (e) {
      _showSnackBar('Location Error: ${e.toString().replaceAll("Exception: ", "")}');
    }
  }

  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_locationCaptured || _lat == null || _lon == null) {
      _showSnackBar('Please capture farm gate GPS coordinates before listing.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final storage = SecureStorageService();
      final userIdStr = await storage.getUserId();
      final farmerId = userIdStr != null ? int.parse(userIdStr) : 1;

      final response = await ApiService.authenticatedRequest(
        method: 'POST',
        endpoint: '/products',
        body: {
          'title': _titleController.text.trim(),
          'category': _category,
          'description': _descriptionController.text.trim(),
          'pricePerUnit': double.parse(_priceController.text.trim()),
          'unitType': _unitType,
          'availableQuantity': double.parse(_quantityController.text.trim()),
          'latitude': _lat,
          'longitude': _lon,
          'farmerId': farmerId,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          _showSnackBar('Produce batch successfully listed on PostGIS spatial registry!');
          Navigator.pop(context);
        }
      } else {
        final err = jsonDecode(response.body);
        throw Exception(err['error'] ?? 'Failed to create produce listing.');
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString().replaceAll("Exception: ", "")}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FR2.1: List Batch Produce'),
        backgroundColor: Colors.green.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Produce Title (e.g. Organic White Maize)', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _category = val!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Price per Unit (XAF)', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Available Batch Quantity', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Batch Description & Harvest Conditions', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: BorderSide(color: _locationCaptured ? Colors.green.shade700 : Colors.grey),
                  backgroundColor: _locationCaptured ? Colors.green.shade50 : null,
                ),
                onPressed: _captureLocation,
                icon: Icon(_locationCaptured ? Icons.check_circle : Icons.gps_fixed, color: _locationCaptured ? Colors.green.shade800 : null),
                label: Text(_locationCaptured ? 'Farm Gate GPS Locked' : 'Capture Farm Gate GPS Location'),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade800, foregroundColor: Colors.white),
                  onPressed: _isLoading ? null : _submitListing,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Publish Batch Listing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}