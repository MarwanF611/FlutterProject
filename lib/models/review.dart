import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String reviewerId;
  final String reviewerName;
  final String revieweeId;
  final String reservationId;
  final String deviceTitle;
  final int rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.reviewerId,
    required this.reviewerName,
    required this.revieweeId,
    required this.reservationId,
    required this.deviceTitle,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromMap(String id, Map<String, dynamic> map) {
    return Review(
      id: id,
      reviewerId: map['reviewerId'] as String,
      reviewerName: map['reviewerName'] as String,
      revieweeId: map['revieweeId'] as String,
      reservationId: map['reservationId'] as String,
      deviceTitle: map['deviceTitle'] as String,
      rating: (map['rating'] as num).toInt(),
      comment: map['comment'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'revieweeId': revieweeId,
      'reservationId': reservationId,
      'deviceTitle': deviceTitle,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
