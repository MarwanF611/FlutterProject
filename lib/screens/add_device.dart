import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../models/device.dart';
import '../providers/auth_provider.dart';
import '../providers/device_provider.dart';
import '../widgets/loading_button.dart';

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();

  String _selectedCategory = kCategories.first;
  bool _isAvailable = true;

  static const int _maxImages = 5;
  final List<Uint8List> _imageBytesList = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).timeout(const Duration(seconds: 8));
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickImages() async {
    final remaining = _maxImages - _imageBytesList.length;
    if (remaining <= 0) return;

    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(
      maxWidth: 1024,
      imageQuality: 75,
      limit: remaining,
    );

    if (picked.isEmpty) return;

    final newBytes = await Future.wait(
      picked.take(remaining).map((xf) => xf.readAsBytes()),
    );

    setState(() {
      _imageBytesList.addAll(newBytes);
    });
  }

  void _removeImage(int index) {
    setState(() => _imageBytesList.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    if (auth.appUser == null) return;

    final position = await _getCurrentLocation();
    if (!mounted) return;

    final device = Device(
      id: '',
      ownerUid: auth.appUser!.uid,
      ownerName: auth.appUser!.displayName,
      ownerCity: auth.appUser!.city,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      category: _selectedCategory,
      pricePerDay: double.parse(_priceController.text.replaceAll(',', '.')),
      isAvailable: _isAvailable,
      createdAt: DateTime.now(),
      lat: position?.latitude,
      lng: position?.longitude,
    );

    final ok = await context.read<DeviceProvider>().addDevice(
          device: device,
          imageBytesList: _imageBytesList,
          ownerUid: auth.appUser!.uid,
        );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Toestel toegevoegd!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              context.read<DeviceProvider>().error ?? 'Toevoegen mislukt.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<DeviceProvider>().loading;
    final canAddMore = _imageBytesList.length < _maxImages;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Toestel toevoegen'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image section ──────────────────────────────────────────
              Text(
                "Foto's (${_imageBytesList.length}/$_maxImages)",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 110,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Existing image thumbnails
                    for (int i = 0; i < _imageBytesList.length; i++)
                      _ImageThumb(
                        bytes: _imageBytesList[i],
                        onRemove: () => _removeImage(i),
                      ),
                    // Add button (only if slots available)
                    if (canAddMore)
                      GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: 100,
                          height: 100,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined,
                                  size: 30,
                                  color: AppColors.primary.withValues(alpha: 0.7)),
                              const SizedBox(height: 4),
                              Text(
                                'Toevoegen',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primary.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              if (_imageBytesList.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 4),
                  child: Text(
                    'Voeg maximaal $_maxImages foto\'s toe',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textLight),
                  ),
                ),

              const SizedBox(height: 20),

              // ── Form fields ────────────────────────────────────────────
              TextFormField(
                controller: _titleController,
                decoration: _fieldDecoration('Naam van het toestel'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Vul een naam in' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: _fieldDecoration('Beschrijving'),
                maxLines: 4,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Vul een beschrijving in' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: _fieldDecoration('Categorie'),
                items: kCategories
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(kCategoryLabels[c]!),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: _fieldDecoration('Prijs per dag (€)'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Vul een prijs in';
                  final price = double.tryParse(v.replaceAll(',', '.'));
                  if (price == null || price <= 0) return 'Ongeldige prijs';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: _isAvailable,
                onChanged: (v) => setState(() => _isAvailable = v),
                title: const Text('Meteen beschikbaar'),
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppColors.primary,
              ),
              const SizedBox(height: 24),
              LoadingButton(
                label: 'Toestel toevoegen',
                isLoading: loading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Image thumbnail widget ─────────────────────────────────────────────────────

class _ImageThumb extends StatelessWidget {
  final Uint8List bytes;
  final VoidCallback onRemove;

  const _ImageThumb({required this.bytes, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          margin: const EdgeInsets.only(right: 10, top: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: MemoryImage(bytes),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 10,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}

InputDecoration _fieldDecoration(String label) {
  return InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}
