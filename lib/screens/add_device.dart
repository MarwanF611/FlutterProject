import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
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
  File? _imageFile;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    if (auth.appUser == null) return;

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
    );

    final ok = await context.read<DeviceProvider>().addDevice(
          device: device,
          imageFile: _imageFile,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Toestel toevoegen'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_imageFile!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo,
                                size: 40, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text('Foto toevoegen',
                                style: TextStyle(color: Colors.grey[500])),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
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
                  final price =
                      double.tryParse(v.replaceAll(',', '.'));
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

InputDecoration _fieldDecoration(String label) {
  return InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}
