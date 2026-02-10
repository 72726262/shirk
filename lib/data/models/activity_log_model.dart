import 'package:equatable/equatable.dart';

class ActivityLogModel extends Equatable {
  final String id;
  final String? userId;
  final String action;
  final String? entityType;
  final String? entityId;
  final String? description;
  final Map<String, dynamic> metadata;
  final String? ipAddress;
  final String? userAgent;
  final DateTime createdAt;

  const ActivityLogModel({
    required this.id,
    this.userId,
    required this.action,
    this.entityType,
    this.entityId,
    this.description,
    this.metadata = const {},
    this.ipAddress,
    this.userAgent,
    required this.createdAt,
  });

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    return ActivityLogModel(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      action: json['action'] as String,
      entityType: json['entity_type'] as String?,
      entityId: json['entity_id'] as String?,
      description: json['description'] as String?,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : {},
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'description': description,
      'metadata': metadata,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        action,
        entityType,
        entityId,
        description,
        metadata,
        ipAddress,
        userAgent,
        createdAt,
      ];
}
