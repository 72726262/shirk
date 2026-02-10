import 'package:equatable/equatable.dart';

enum DefectCategory {
  paint,
  flooring,
  plumbing,
  electrical,
  doors,
  windows,
  ceiling,
  walls,
  other,
}

enum DefectSeverity { low, medium, high, critical }

enum DefectStatus { pending, acknowledged, fixing, fixed, rejected, closed }

class DefectModel extends Equatable {
  final String id;
  final String handoverId;
  final DefectCategory category;
  final String description;
  final String? location;
  final DefectSeverity severity;
  final List<String> photos;
  final DefectStatus status;
  final String? adminComment;
  final DateTime reportedAt;
  final DateTime? fixedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DefectModel({
    required this.id,
    required this.handoverId,
    required this.category,
    required this.description,
    this.location,
    required this.severity,
    this.photos = const [],
    required this.status,
    this.adminComment,
    required this.reportedAt,
    this.fixedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  // Constructor جديد للسهولة مع دعم title
  factory DefectModel.create({
    required String handoverId,
    required String description,
    DefectCategory category = DefectCategory.other,
    DefectSeverity severity = DefectSeverity.medium,
    String? location,
    List<String> photos = const [],
    String? title, // اختياري للتوافق مع الكود القديم
  }) {
    final fullDescription = title != null
        ? '$title: $description'
        : description;

    return DefectModel(
      id: '', // سيتم تعيينه من السيرفر
      handoverId: handoverId,
      category: category,
      description: fullDescription,
      location: location,
      severity: severity,
      photos: photos,
      status: DefectStatus.pending,
      adminComment: null,
      reportedAt: DateTime.now(),
      fixedAt: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Constructor من JSON
  factory DefectModel.fromJson(Map<String, dynamic> json) {
    return DefectModel(
      id: json['id'] as String,
      handoverId: json['handover_id'] as String,
      category: DefectCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => DefectCategory.other,
      ),
      description: json['description'] as String,
      location: json['location'] as String?,
      severity: DefectSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => DefectSeverity.medium,
      ),
      photos: json['photos'] != null
          ? List<String>.from(json['photos'] as List)
          : [],
      status: DefectStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DefectStatus.pending,
      ),
      adminComment: json['admin_comment'] as String?,
      reportedAt: DateTime.parse(json['reported_at'] as String),
      fixedAt: json['fixed_at'] != null
          ? DateTime.parse(json['fixed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // Constructor لإنشاء نسخة معدلة
  DefectModel copyWith({
    String? id,
    String? handoverId,
    DefectCategory? category,
    String? description,
    String? location,
    DefectSeverity? severity,
    List<String>? photos,
    DefectStatus? status,
    String? adminComment,
    DateTime? reportedAt,
    DateTime? fixedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DefectModel(
      id: id ?? this.id,
      handoverId: handoverId ?? this.handoverId,
      category: category ?? this.category,
      description: description ?? this.description,
      location: location ?? this.location,
      severity: severity ?? this.severity,
      photos: photos ?? this.photos,
      status: status ?? this.status,
      adminComment: adminComment ?? this.adminComment,
      reportedAt: reportedAt ?? this.reportedAt,
      fixedAt: fixedAt ?? this.fixedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'handover_id': handoverId,
      'category': category.name,
      'description': description,
      'location': location,
      'severity': severity.name,
      'photos': photos,
      'status': status.name,
      'admin_comment': adminComment,
      'reported_at': reportedAt.toIso8601String(),
      'fixed_at': fixedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Convert to JSON for API (بدون id للإنشاء الجديد)
  Map<String, dynamic> toJsonForCreate() {
    return {
      'handover_id': handoverId,
      'category': category.name,
      'description': description,
      'location': location,
      'severity': severity.name,
      'photos': photos,
      'status': status.name,
      'admin_comment': adminComment,
      'reported_at': reportedAt.toIso8601String(),
    };
  }

  // Getters
  bool get isFixed => status == DefectStatus.fixed;
  bool get isPending => status == DefectStatus.pending;
  bool get isFixing => status == DefectStatus.fixing;
  bool get isCritical => severity == DefectSeverity.critical;
  bool get isAcknowledged => status == DefectStatus.acknowledged;
  bool get isClosed => status == DefectStatus.closed;

  // Title getter for display purposes
  String get title => description.length > 30
      ? '${description.substring(0, 30)}...'
      : description;

  // Getter للوصف المختصر
  String get shortDescription {
    if (description.length <= 50) return description;
    return '${description.substring(0, 50)}...';
  }

  // الترجمة العربية
  String get categoryAr {
    switch (category) {
      case DefectCategory.paint:
        return 'دهان';
      case DefectCategory.flooring:
        return 'أرضيات';
      case DefectCategory.plumbing:
        return 'سباكة';
      case DefectCategory.electrical:
        return 'كهرباء';
      case DefectCategory.doors:
        return 'أبواب';
      case DefectCategory.windows:
        return 'نوافذ';
      case DefectCategory.ceiling:
        return 'سقف';
      case DefectCategory.walls:
        return 'جدران';
      case DefectCategory.other:
        return 'أخرى';
    }
  }

  String get severityAr {
    switch (severity) {
      case DefectSeverity.low:
        return 'منخفضة';
      case DefectSeverity.medium:
        return 'متوسطة';
      case DefectSeverity.high:
        return 'عالية';
      case DefectSeverity.critical:
        return 'حرجة';
    }
  }

  String get statusAr {
    switch (status) {
      case DefectStatus.pending:
        return 'قيد الانتظار';
      case DefectStatus.acknowledged:
        return 'معترف به';
      case DefectStatus.fixing:
        return 'قيد الإصلاح';
      case DefectStatus.fixed:
        return 'مُصلح';
      case DefectStatus.rejected:
        return 'مرفوض';
      case DefectStatus.closed:
        return 'مغلق';
    }
  }

  // Icon لكل حالة
  String get statusIcon {
    switch (status) {
      case DefectStatus.pending:
        return '⏳';
      case DefectStatus.acknowledged:
        return '✅';
      case DefectStatus.fixing:
        return '🔧';
      case DefectStatus.fixed:
        return '🎯';
      case DefectStatus.rejected:
        return '❌';
      case DefectStatus.closed:
        return '🔒';
    }
  }

  // Color لكل خطورة
  String get severityColor {
    switch (severity) {
      case DefectSeverity.low:
        return '#4CAF50'; // أخضر
      case DefectSeverity.medium:
        return '#FFC107'; // أصفر
      case DefectSeverity.high:
        return '#FF9800'; // برتقالي
      case DefectSeverity.critical:
        return '#F44336'; // أحمر
    }
  }

  // التحقق من الصلاحية
  bool get isValid {
    return handoverId.isNotEmpty &&
        description.isNotEmpty &&
        description.length >= 5;
  }

  // حساب الأيام منذ الإبلاغ
  int get daysSinceReport {
    final now = DateTime.now();
    return now.difference(reportedAt).inDays;
  }

  @override
  List<Object?> get props => [
    id,
    handoverId,
    category,
    description,
    location,
    severity,
    photos,
    status,
    adminComment,
    reportedAt,
    fixedAt,
    createdAt,
    updatedAt,
  ];
}

// Helper class for defect statistics
class DefectStats {
  final int total;
  final int pending;
  final int fixed;
  final int critical;
  final int inProgress;

  const DefectStats({
    required this.total,
    required this.pending,
    required this.fixed,
    required this.critical,
    required this.inProgress,
  });

  factory DefectStats.fromDefects(List<DefectModel> defects) {
    return DefectStats(
      total: defects.length,
      pending: defects.where((d) => d.isPending).length,
      fixed: defects.where((d) => d.isFixed).length,
      critical: defects.where((d) => d.isCritical).length,
      inProgress: defects.where((d) => d.isFixing).length,
    );
  }

  double get completionRate {
    if (total == 0) return 0.0;
    return (fixed / total) * 100;
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'pending': pending,
      'fixed': fixed,
      'critical': critical,
      'in_progress': inProgress,
      'completion_rate': completionRate,
    };
  }
}
