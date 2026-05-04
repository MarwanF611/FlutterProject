import 'dart:async';
import 'dart:convert';
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
  // Als [device] meegegeven wordt, is dit edit-modus
  final Device? device;
  const AddDeviceScreen({super.key, this.device});

  bool get isEditing => device != null;

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

  // Bestaande afbeeldingen (URL of base64) — komen uit Firestore
  final List<String> _existingImageUrls = [];
  // Nieuwe afbeeldingen die de gebruiker heeft toegevoegd
  final List<Uint8List> _newImageBytesList = [];

  int get _totalImages => _existingImageUrls.length + _newImageBytesList.length;
  bool get _canAddMore => _totalImages < _maxImages;

  @override
  void initState() {
    super.initState();
    final d = widget.device;
    if (d != null) {
      _titleController.text = d.title;
      _descController.text = d.description;
      _priceController.text = d.pricePerDay.toStringAsFixed(2);
      _selectedCategory = d.category;
      _isAvailable = d.isAvailable;
      _existingImageUrls.addAll(d.imageUrls);
    }
  }

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
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      ).timeout(const Duration(seconds: 8));
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickImages() async {
    final remaining = _maxImages - _totalImages;
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
    setState(() => _newImageBytesList.addAll(newBytes));
  }

  void _removeExisting(int index) =>
      setState(() => _existingImageUrls.removeAt(index));

  void _removeNew(int index) =>
      setState(() => _newImageBytesList.removeAt(index));

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    if (auth.appUser == null) return;

    final provider = context.read<DeviceProvider>();
    final price = double.parse(_priceController.text.replaceAll(',', '.'));
    bool ok;

    if (widget.isEditing) {
      // Edit-modus: update het bestaande toestel
      final updated = Device(
        id: widget.device!.id,
        ownerUid: widget.device!.ownerUid,
        ownerName: widget.device!.ownerName,
        ownerCity: widget.device!.ownerCity,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        category: _selectedCategory,
        pricePerDay: price,
        isAvailable: _isAvailable,
        createdAt: widget.device!.createdAt,
        lat: widget.device!.lat,
        lng: widget.device!.lng,
      );
      ok = await provider.updateDevice(
        device: updated,
        newImageBytesList: _newImageBytesList,
        keepImageUrls: _existingImageUrls,
        ownerUid: auth.appUser!.uid,
      );
    } else {
      // Toevoegen-modus: haal locatie op en maak nieuw toestel
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
        pricePerDay: price,
        isAvailable: _isAvailable,
        createdAt: DateTime.now(),
        lat: position?.latitude,
        lng: position?.longitude,
      );
      ok = await provider.addDevice(
        device: device,
        imageBytesList: _newImageBytesList,
        ownerUid: auth.appUser!.uid,
      );
    }

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEditing
              ? 'Toestel bijgewerkt!'
              : 'Toestel toegevoegd!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Opslaan mislukt.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<DeviceProvider>().loading;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Toestel bewerken' : 'Toestel toevoegen'),
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
              // ── Foto sectie ───────────────────────────────────────────────
              Text(
                "Foto's ($_totalImages/$_maxImages)",
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
                    // Bestaande foto's (URL of base64)
                    for (int i = 0; i < _existingImageUrls.length; i++)
                      _ExistingImageThumb(
                        url: _existingImageUrls[i],
                        onRemove: () => _removeExisting(i),
                      ),
                    // Nieuwe foto's (Uint8List)
                    for (int i = 0; i < _newImageBytesList.length; i++)
                      _NewImageThumb(
                        bytes: _newImageBytesList[i],
                        onRemove: () => _removeNew(i),
                      ),
                    // Toevoegen-knop
                    if (_canAddMore)
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

              if (_totalImages == 0)
                const Padding(
                  padding: EdgeInsets.only(top: 4, bottom: 4),
                  child: Text(
                    'Voeg maximaal 5 foto\'s toe',
                    style: TextStyle(fontSize: 12, color: AppColors.textLight),
                  ),
                ),

              const SizedBox(height: 20),

              // ── Formuliervelden ───────────────────────────────────────────
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
                title: const Text('Beschikbaar voor verhuur'),
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppColors.primary,
              ),
              const SizedBox(height: 24),
              LoadingButton(
                label: widget.isEditing ? 'Wijzigingen opslaan' : 'Toestel toevoegen',
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

// ── Bestaande afbeelding thumbnail (URL of base64) ────────────────────────────

class _ExistingImageThumb extends StatelessWidget {
  final String url;
  final VoidCallback onRemove;

  const _ExistingImageThumb({required this.url, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    Widget img;
    if (url.startsWith('http')) {
      img = Image.network(url, fit: BoxFit.cover, width: 100, height: 100,
          errorBuilder: (ctx, err, stack) =>
              const Icon(Icons.broken_image, color: AppColors.textLight));
    } else {
      try {
        img = Image.memory(base64Decode(url),
            fit: BoxFit.cover, width: 100, height: 100);
      } catch (_) {
        img = const Icon(Icons.broken_image, color: AppColors.textLight);
      }
    }

    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          margin: const EdgeInsets.only(right: 10, top: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppColors.bgGrey,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: img,
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
                  color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Nieuwe afbeelding thumbnail (Uint8List) ───────────────────────────────────

class _NewImageThumb extends StatelessWidget {
  final Uint8List bytes;
  final VoidCallback onRemove;

  const _NewImageThumb({required this.bytes, required this.onRemove});

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
                  color: Colors.red, shape: BoxShape.circle),
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
