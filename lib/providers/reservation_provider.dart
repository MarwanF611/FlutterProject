import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/device.dart';
import '../models/reservation.dart';
import '../services/firestore_service.dart';

class ReservationProvider extends ChangeNotifier {
  final FirestoreService _fs;
  bool _loading = false;
  String? _error;

  ReservationProvider(this._fs);

  bool get loading => _loading;
  String? get error => _error;

  Stream<List<Reservation>> tenantReservationsStream(String tenantUid) {
    return _fs.getReservationsForTenant(tenantUid);
  }

  Stream<List<Reservation>> ownerReservationsStream(String ownerUid) {
    return _fs.getReservationsForOwner(ownerUid);
  }

  Future<List<Reservation>> getApprovedReservations(String deviceId) {
    return _fs.getApprovedReservations(deviceId);
  }

  Future<bool> reserve({
    required Device device,
    required DateTime start,
    required DateTime end,
    required AppUser tenant,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      // Server-side conflict check — wrapped separately so a failure here
      // never blocks the actual reservation from being created.
      try {
        final approved = await _fs.getApprovedReservations(device.id);
        final conflict = approved.any(
            (r) => !start.isAfter(r.endDate) && !end.isBefore(r.startDate));
        if (conflict) {
          _error =
              'De geselecteerde periode overlapt met een bestaande reservering.';
          _loading = false;
          notifyListeners();
          return false;
        }
      } catch (_) {
        // Conflict check failed (e.g. permissions) — proceed with reservation.
      }

      final days = end.difference(start).inDays + 1;
      final reservation = Reservation(
        id: '',
        deviceId: device.id,
        deviceTitle: device.title,
        tenantUid: tenant.uid,
        tenantName: tenant.displayName,
        ownerUid: device.ownerUid,
        startDate: start,
        endDate: end,
        totalPrice: days * device.pricePerDay,
        status: 'pending',
        createdAt: DateTime.now(),
      );
      await _fs.createReservation(reservation);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Reservering mislukt. Probeer opnieuw.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> approveReservation(
      String reservationId, String deviceId) async {
    await _fs.updateReservationStatus(reservationId, 'approved', deviceId);
  }

  Future<void> rejectReservation(
      String reservationId, String deviceId) async {
    await _fs.updateReservationStatus(reservationId, 'rejected', deviceId);
  }
}
