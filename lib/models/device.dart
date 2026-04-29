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
  final List<String> imageUrls;
  final double pricePerDay;
  final bool isAvailable;
  final DateTime createdAt;
  final double? lat;
  final double? lng;

  Device({
    required this.id,
    required this.ownerUid,
    required this.ownerName,
    required this.ownerCity,
    required this.title,
    required this.description,
    required this.category,
    this.imageUrls = const [],
    required this.pricePerDay,
    required this.isAvailable,
    required this.createdAt,
    this.lat,
    this.lng,
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
      imageUrls: (map['imageUrls'] as List<dynamic>? ?? []).cast<String>(),
      pricePerDay: (map['pricePerDay'] as num).toDouble(),
      isAvailable: map['isAvailable'] as bool,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
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
      'imageUrls': imageUrls,
      'pricePerDay': pricePerDay,
      'isAvailable': isAvailable,
      'createdAt': Timestamp.fromDate(createdAt),
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    };
  }
}
