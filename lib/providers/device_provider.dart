import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/device.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class DeviceProvider extends ChangeNotifier {
  final FirestoreService _fs;
  // ignore: unused_field
  final StorageService _ss;

  String? _selectedCategory;
  bool _loading = false;
  String? _error;

  DeviceProvider(this._fs, this._ss);

  String? get selectedCategory => _selectedCategory;
  bool get loading => _loading;
  String? get error => _error;

  Stream<List<Device>> get devicesStream {
    if (_selectedCategory == null) return _fs.getAvailableDevices();
    return _fs.getDevicesByCategory(_selectedCategory!);
  }

  Stream<List<Device>> ownerDevicesStream(String ownerUid) =>
      _fs.getDevicesByOwner(ownerUid);

  void selectCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<bool> addDevice({
    required Device device,
    List<Uint8List> imageBytesList = const [],
    required String ownerUid,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final imageUrls = imageBytesList.map(base64Encode).toList();

      final deviceWithImages = Device(
        id: device.id,
        ownerUid: device.ownerUid,
        ownerName: device.ownerName,
        ownerCity: device.ownerCity,
        title: device.title,
        description: device.description,
        category: device.category,
        imageUrls: imageUrls,
        pricePerDay: device.pricePerDay,
        isAvailable: device.isAvailable,
        createdAt: device.createdAt,
        lat: device.lat,
        lng: device.lng,
      );
      await _fs.addDevice(deviceWithImages);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Kon toestel niet toevoegen. Probeer opnieuw.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateDevice({
    required Device device,
    List<Uint8List> newImageBytesList = const [],
    List<String> keepImageUrls = const [],
    required String ownerUid,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final newBase64 = newImageBytesList.map(base64Encode).toList();

      final updated = Device(
        id: device.id,
        ownerUid: device.ownerUid,
        ownerName: device.ownerName,
        ownerCity: device.ownerCity,
        title: device.title,
        description: device.description,
        category: device.category,
        imageUrls: [...keepImageUrls, ...newBase64],
        pricePerDay: device.pricePerDay,
        isAvailable: device.isAvailable,
        createdAt: device.createdAt,
        lat: device.lat,
        lng: device.lng,
      );
      await _fs.updateDevice(updated);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Kon toestel niet bijwerken. Probeer opnieuw.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleAvailability(String deviceId, bool current) async {
    await _fs.updateDeviceAvailability(deviceId, !current);
  }

  Future<void> removeDevice(String deviceId) async {
    await _fs.deleteDevice(deviceId);
  }
}
