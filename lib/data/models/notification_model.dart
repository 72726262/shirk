import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum NotificationType {
  general,
  info,
  success,
  warning, // Use for alerts/errors
  error,
  update, // General updates
  payment, // Payment reminders/confirmations
  kyc, // KYC status changes
  document, // Document requests/signatures
  handover, // Handover milestones
  message, // New chat messages
  request_approved, // Specific approval notifications
  construction_update; // Specific construction progress

  String toJson() => name;
  
  static NotificationType fromJson(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationType.info,
    );
  }

  String get displayName {
    switch (this) {
      case NotificationType.general:
        return 'عام';
      case NotificationType.info:
        return 'تنبيه';
      case NotificationType.success:
        return 'نجاح';
      case NotificationType.warning:
        return 'تحذير';
      case NotificationType.error:
        return 'خطأ';
      case NotificationType.update:
        return 'تحديث';
      case NotificationType.payment:
        return 'المدفوعات';
      case NotificationType.kyc:
        return 'التحقق من الهوية';
      case NotificationType.document:
        return 'المستندات';
      case NotificationType.handover:
        return 'التسليم';
      case NotificationType.message:
        return 'رسالة جديدة';
      case NotificationType.request_approved:
        return 'تمت الموافقة';
      case NotificationType.construction_update:
        return 'تطورات البناء';
    }
  }

  IconData get displayIcon {
    switch (this) {
      case NotificationType.general:
        return Icons.notifications;
      case NotificationType.info:
        return Icons.info_outline;
      case NotificationType.success:
        return Icons.check_circle_outline;
      case NotificationType.warning:
        return Icons.warning_amber_rounded;
      case NotificationType.error:
        return Icons.error_outline;
      case NotificationType.update:
        return Icons.update;
      case NotificationType.payment:
        return Icons.payment;
      case NotificationType.kyc:
        return Icons.verified_user;
      case NotificationType.document:
        return Icons.description;
      case NotificationType.handover:
        return Icons.key;
      case NotificationType.message:
        return Icons.chat_bubble_outline;
      case NotificationType.request_approved:
        return Icons.check_circle;
      case NotificationType.construction_update:
        return Icons.construction;
    }
  }

  Color get displayColor {
    switch (this) {
      case NotificationType.success:
      case NotificationType.request_approved:
        return Colors.green;
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.error:
        return Colors.red;
      case NotificationType.info:
      case NotificationType.message:
        return Colors.blue;
      case NotificationType.construction_update:
        return Colors.orangeAccent;
      case NotificationType.payment:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
enum NotificationPriority {
  low,
  normal,
  high,
  urgent;

  String toJson() => name;
  
  static NotificationPriority fromJson(String value) {
    return NotificationPriority.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationPriority.normal,
    );
  }
}

class NotificationModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String? titleAr;
  final String body;
  final String? bodyAr;
  final NotificationType type;
  final String? projectId;
  final String? subscriptionId;
  final String? documentId;
  final String? icon;
  final String? imageUrl;
  final String? actionUrl;
  final String? actionLabel;
  final bool isRead;
  final DateTime? readAt;
  final NotificationPriority priority;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    this.titleAr,
    required this.body,
    this.bodyAr,
    this.type = NotificationType.info,
    this.projectId,
    this.subscriptionId,
    this.documentId,
    this.icon,
    this.imageUrl,
    this.actionUrl,
    this.actionLabel,
    this.isRead = false,
    this.readAt,
    this.priority = NotificationPriority.normal,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      titleAr: json['title_ar'] as String?,
      body: json['body'] as String,
      bodyAr: json['body_ar'] as String?,
      type: json['type'] != null
          ? NotificationType.fromJson(json['type'] as String)
          : NotificationType.info,
      projectId: json['project_id'] as String?,
      subscriptionId: json['subscription_id'] as String?,
      documentId: json['document_id'] as String?,
      icon: json['icon'] as String?,
      imageUrl: json['image_url'] as String?,
      actionUrl: json['action_url'] as String?,
      actionLabel: json['action_label'] as String?,
      isRead: (json['is_read'] as bool?) ?? false,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      priority: json['priority'] != null
          ? NotificationPriority.fromJson(json['priority'] as String)
          : NotificationPriority.normal,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'title_ar': titleAr,
      'body': body,
      'body_ar': bodyAr,
      'type': type.toJson(),
      'project_id': projectId,
      'subscription_id': subscriptionId,
      'document_id': documentId,
      'icon': icon,
      'image_url': imageUrl,
      'action_url': actionUrl,
      'action_label': actionLabel,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'priority': priority.toJson(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? titleAr,
    String? body,
    String? bodyAr,
    NotificationType? type,
    String? projectId,
    String? subscriptionId,
    String? documentId,
    String? icon,
    String? imageUrl,
    String? actionUrl,
    String? actionLabel,
    bool? isRead,
    DateTime? readAt,
    NotificationPriority? priority,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      titleAr: titleAr ?? this.titleAr,
      body: body ?? this.body,
      bodyAr: bodyAr ?? this.bodyAr,
      type: type ?? this.type,
      projectId: projectId ?? this.projectId,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      documentId: documentId ?? this.documentId,
      icon: icon ?? this.icon,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      actionLabel: actionLabel ?? this.actionLabel,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        titleAr,
        body,
        bodyAr,
        type,
        projectId,
        subscriptionId,
        documentId,
        icon,
        imageUrl,
        actionUrl,
        actionLabel,
        isRead,
        readAt,
        priority,
        createdAt,
      ];
}
