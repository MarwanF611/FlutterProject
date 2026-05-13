import 'dart:async';
import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/device.dart';
import '../models/reservation.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class ReservationProvider extends ChangeNotifier {
  final FirestoreService _fs;
  bool _loading = false;
  String? _error;

  StreamSubscription? _reservationSub;
  final Set<String> _seenIds = {};
  int _unreadCount = 0;

  ReservationProvider(this._fs);

  bool get loading => _loading;
  String? get error => _error;
  int get unreadCount => _unreadCount;

  void clearUnread() {
    if (_unreadCount == 0) return;
    _unreadCount = 0;
    notifyListeners();
  }

  void startReservationListener(String ownerUid) {
    stopReservationListener();
    bool firstEmission = true;

    _reservationSub = _fs.getReservationsForOwner(ownerUid).listen((list) {
      if (firstEmission) {
        for (final r in list) {
          _seenIds.add(r.id);
        }
        firstEmission = false;
        return;
      }

      for (final r in list) {
        if (!_seenIds.contains(r.id) && r.status == 'pending') {
          _seenIds.add(r.id);
          _unreadCount++;
          notifyListeners();
          NotificationService.showNotification(
            id: r.id.hashCode,
            title: '📦 Nieuwe reserveringsaanvraag',
            body: '${r.tenantName} wil "${r.deviceTitle}" huren.',
          );
        }
      }
    });
  }

  void stopReservationListener() {
    _reservationSub?.cancel();
    _reservationSub = null;
    _seenIds.clear();
    _unreadCount = 0;
  }

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

  /// Checks approved reservations for the tenant and fires local notifications
  /// when start or end date is today or tomorrow.
  Future<void> checkUpcomingReminders(String tenantUid) async {
    try {
      final reservations =
          await _fs.getApprovedReservationsForTenant(tenantUid);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      for (final r in reservations) {
        final start =
            DateTime(r.startDate.year, r.startDate.month, r.startDate.day);
        final end =
            DateTime(r.endDate.year, r.endDate.month, r.endDate.day);

        if (start == today) {
          NotificationService.showNotification(
            id: 'start_today_${r.id}'.hashCode,
            title: '📦 Vandaag ophalen!',
            body: 'Je kunt "${r.deviceTitle}" vandaag ophalen.',
          );
        } else if (start == tomorrow) {
          NotificationService.showNotification(
            id: 'start_tomorrow_${r.id}'.hashCode,
            title: '⏰ Morgen ophalen',
            body: 'Vergeet niet: morgen mag je "${r.deviceTitle}" ophalen.',
          );
        }

        if (end == today) {
          NotificationService.showNotification(
            id: 'end_today_${r.id}'.hashCode,
            title: '🔔 Huurperiode eindigt vandaag',
            body: 'Je huurperiode voor "${r.deviceTitle}" eindigt vandaag.',
          );
        } else if (end == tomorrow) {
          NotificationService.showNotification(
            id: 'end_tomorrow_${r.id}'.hashCode,
            title: '⚠️ Huurperiode eindigt morgen',
            body: 'Je huurperiode voor "${r.deviceTitle}" eindigt morgen.',
          );
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    stopReservationListener();
    super.dispose();
  }
}
