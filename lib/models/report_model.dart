import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String reportId;
  final String reporterId;
  final String reporterName;
  final String reportedId; // Can be rideId or userId
  final String type; // 'ride', 'user', 'safety', 'app'
  final String category; // 'Behavior', 'Technical', 'Safety', 'Payment', etc.
  final String description;
  final String status; // 'pending', 'investigating', 'resolved', 'dismissed'
  final DateTime createdAt;
  final Map<String, dynamic>? metadata; // For rideId, bookingId etc.

  ReportModel({
    required this.reportId,
    required this.reporterId,
    required this.reporterName,
    required this.reportedId,
    required this.type,
    required this.category,
    required this.description,
    this.status = 'pending',
    required this.createdAt,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'reportId': reportId,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'reportedId': reportedId,
      'type': type,
      'category': category,
      'description': description,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'metadata': metadata,
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map) {
    return ReportModel(
      reportId: map['reportId'] ?? '',
      reporterId: map['reporterId'] ?? '',
      reporterName: map['reporterName'] ?? '',
      reportedId: map['reportedId'] ?? '',
      type: map['type'] ?? 'general',
      category: map['category'] ?? 'Other',
      description: map['description'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: map['metadata'],
    );
  }
}
