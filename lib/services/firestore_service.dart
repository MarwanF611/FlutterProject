import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/device.dart';
import '../models/reservation.dart';
import '../models/chat.dart';

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

  Future<void> updateDevice(Device device) {
    return _db.collection('devices').doc(device.id).update(device.toMap());
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
    // Don't mark isAvailable = false here anymore, because reservations can be for specific dates.
    // Instead we will rely on checking approved reservations.
    await batch.commit();
  }

  Future<List<Reservation>> getApprovedReservations(String deviceId) async {
    final snap = await _db
        .collection('reservations')
        .where('deviceId', isEqualTo: deviceId)
        .where('status', isEqualTo: 'approved')
        .get();
    return snap.docs
        .map((doc) => Reservation.fromMap(doc.id, doc.data()))
        .toList();
  }

  // --- Chats ---

  Stream<List<Chat>> getUserChats(String uid) {
    return _db
        .collection('chats')
        .where('participants', arrayContains: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Chat.fromMap(doc.id, doc.data())).toList());
  }

  Stream<List<ChatMessage>> getChatMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ChatMessage.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> sendMessage(String chatId, ChatMessage message) async {
    final batch = _db.batch();
    
    // Add raw message to subcollection
    final messageRef = _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(message.id.isEmpty ? null : message.id);
    batch.set(messageRef, message.toMap());

    // Update last message in the chat
    final chatRef = _db.collection('chats').doc(chatId);
    batch.update(chatRef, {
      'lastMessage': message.text,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<String> getOrCreateChat({
    required String tenantUid,
    required String ownerUid,
    required String tenantName,
    required String ownerName,
    required String deviceId,
    required String deviceTitle,
  }) async {
    // Check if chat already exists for these 2 people and this device
    final qs = await _db
        .collection('chats')
        .where('participants', arrayContains: tenantUid)
        .get();
    
    for (var doc in qs.docs) {
      final chat = Chat.fromMap(doc.id, doc.data());
      if (chat.participants.contains(ownerUid) && chat.deviceId == deviceId) {
        return chat.id;
      }
    }

    // Create new
    final newChat = Chat(
      id: '',
      participants: [tenantUid, ownerUid],
      participantNames: {tenantUid: tenantName, ownerUid: ownerName},
      deviceId: deviceId,
      deviceTitle: deviceTitle,
      lastMessage: '',
      updatedAt: DateTime.now(),
    );
    final ref = await _db.collection('chats').add(newChat.toMap());
    return ref.id;
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
