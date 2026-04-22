import 'package:cloud_firestore/cloud_firestore.dart';

class Reservation {
  final String id;
  final String deviceId;
  final String deviceTitle;
  final String tenantUid;
  final String tenantName;
  final String ownerUid;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final String status;
  final DateTime createdAt;

  Reservation({
    required this.id,
    required this.deviceId,
    required this.deviceTitle,
    required this.tenantUid,
    required this.tenantName,
    required this.ownerUid,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
  });

  int get durationDays => endDate.difference(startDate).inDays + 1;

  factory Reservation.fromMap(String id, Map<String, dynamic> map) {
    return Reservation(
      id: id,
      deviceId: map['deviceId'] as String,
      deviceTitle: map['deviceTitle'] as String,
      tenantUid: map['tenantUid'] as String,
      tenantName: map['tenantName'] as String,
      ownerUid: map['ownerUid'] as String,
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      totalPrice: (map['totalPrice'] as num).toDouble(),
      status: map['status'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'deviceTitle': deviceTitle,
      'tenantUid': tenantUid,
      'tenantName': tenantName,
      'ownerUid': ownerUid,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'totalPrice': totalPrice,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
