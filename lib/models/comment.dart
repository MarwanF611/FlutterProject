import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String userId;
  final String userName;
  final String deviceId;
  final String text;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.deviceId,
    required this.text,
    required this.createdAt,
  });

  factory Comment.fromMap(String id, Map<String, dynamic> map) {
    return Comment(
      id: id,
      userId: map['userId'] as String,
      userName: map['userName'] as String,
      deviceId: map['deviceId'] as String,
      text: map['text'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'deviceId': deviceId,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
