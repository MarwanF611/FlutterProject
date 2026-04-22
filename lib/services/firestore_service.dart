import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/device.dart';
import '../models/reservation.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Devices ---

  Future<String> addDevice(Device device) async {
    final ref = await _db.collection('devices').add(device.toMap());
    return ref.id;
  }

  Stream<List<Device>> getAvailableDevices() {
    return _db
        .collection('devices')
        .where('isAvailable', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Device.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<Device>> getDevicesByCategory(String category) {
    return _db
        .collection('devices')
        .where('isAvailable', isEqualTo: true)
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Device.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<Device>> getDevicesByOwner(String ownerUid) {
    return _db
        .collection('devices')
        .where('ownerUid', isEqualTo: ownerUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Device.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> updateDeviceAvailability(String deviceId, bool isAvailable) {
    return _db
        .collection('devices')
        .doc(deviceId)
        .update({'isAvailable': isAvailable});
  }

  Future<void> deleteDevice(String deviceId) {
    return _db.collection('devices').doc(deviceId).delete();
  }

  // --- Reservations ---

  Future<String> createReservation(Reservation reservation) async {
    final ref =
        await _db.collection('reservations').add(reservation.toMap());
    return ref.id;
  }

  Stream<List<Reservation>> getReservationsForTenant(String tenantUid) {
    return _db
        .collection('reservations')
        .where('tenantUid', isEqualTo: tenantUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Reservation.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<Reservation>> getReservationsForOwner(String ownerUid) {
    return _db
        .collection('reservations')
        .where('ownerUid', isEqualTo: ownerUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Reservation.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> updateReservationStatus(
      String reservationId, String status, String deviceId) async {
    final batch = _db.batch();
    batch.update(
      _db.collection('reservations').doc(reservationId),
      {'status': status},
    );
    if (status == 'approved') {
      batch.update(
        _db.collection('devices').doc(deviceId),
        {'isAvailable': false},
      );
    } else if (status == 'rejected') {
      batch.update(
        _db.collection('devices').doc(deviceId),
        {'isAvailable': true},
      );
    }
    await batch.commit();
  }

  // --- Users ---

  Future<AppUser?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(uid, doc.data()!);
  }

  Future<void> updateUser(AppUser user) {
    return _db.collection('users').doc(user.uid).update(user.toMap());
  }
}
