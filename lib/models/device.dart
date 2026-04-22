import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

const kCategories = [
  'stofzuiger',
  'grasmaaier',
  'keukenmachine',
  'gereedschap',
  'overige',
];

const kCategoryLabels = {
  'stofzuiger': 'Stofzuigers',
  'grasmaaier': 'Grasmaaiers',
  'keukenmachine': 'Keukenmachines',
  'gereedschap': 'Gereedschap',
  'overige': 'Overige',
};

const kCategoryIcons = {
  'stofzuiger': Icons.cleaning_services,
  'grasmaaier': Icons.grass,
  'keukenmachine': Icons.blender,
  'gereedschap': Icons.construction,
  'overige': Icons.devices_other,
};

class Device {
  final String id;
  final String ownerUid;
  final String ownerName;
  final String ownerCity;
  final String title;
  final String description;
  final String category;
  final String? imageUrl;
  final double pricePerDay;
  final bool isAvailable;
  final DateTime createdAt;

  Device({
    required this.id,
    required this.ownerUid,
    required this.ownerName,
    required this.ownerCity,
    required this.title,
    required this.description,
    required this.category,
    this.imageUrl,
    required this.pricePerDay,
    required this.isAvailable,
    required this.createdAt,
  });

  factory Device.fromMap(String id, Map<String, dynamic> map) {
    return Device(
      id: id,
      ownerUid: map['ownerUid'] as String,
      ownerName: map['ownerName'] as String,
      ownerCity: map['ownerCity'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      category: map['category'] as String,
      imageUrl: map['imageUrl'] as String?,
      pricePerDay: (map['pricePerDay'] as num).toDouble(),
      isAvailable: map['isAvailable'] as bool,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerUid': ownerUid,
      'ownerName': ownerName,
      'ownerCity': ownerCity,
      'title': title,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'pricePerDay': pricePerDay,
      'isAvailable': isAvailable,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
