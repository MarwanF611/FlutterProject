import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/device.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class DeviceProvider extends ChangeNotifier {
  final FirestoreService _fs;
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
      // Upload images to Firebase Storage, store URLs in Firestore
      final imageUrls = await Future.wait(
        imageBytesList.map(
          (bytes) => _ss.uploadDeviceImage(uid: ownerUid, imageBytes: bytes),
        ),
      );

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
      final newUrls = await Future.wait(
        newImageBytesList.map(
          (bytes) => _ss.uploadDeviceImage(uid: ownerUid, imageBytes: bytes),
        ),
      );
      final updated = Device(
        id: device.id,
        ownerUid: device.ownerUid,
        ownerName: device.ownerName,
        ownerCity: device.ownerCity,
        title: device.title,
        description: device.description,
        category: device.category,
        imageUrls: [...keepImageUrls, ...newUrls],
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
