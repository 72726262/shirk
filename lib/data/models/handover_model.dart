import 'package:equatable/equatable.dart';

enum HandoverStatus {
  scheduled,
  notStarted,
  appointmentBooked,
  inspectionPending,
  defectsSubmitted,
  defectsFixing,
  readyForHandover,
  completed,
  inProgress,
  cancelled;

  String toJson() => name;

  static HandoverStatus fromJson(String value) {
    if (value == 'scheduled')
      return HandoverStatus.appointmentBooked; // Backwards compatibility
    if (value == 'in_progress') return HandoverStatus.inspectionPending;
    if (value == 'snag_list_submitted') return HandoverStatus.defectsSubmitted;
    if (value == 'defects_fixed') return HandoverStatus.defectsFixing;

    return HandoverStatus.values.firstWhere(
      (e) => e.name == value || e.name == value.replaceAll('_', ''),
      orElse: () => HandoverStatus.notStarted,
    );
  }

  String get displayName {
    switch (this) {
      case HandoverStatus.scheduled:
        return 'مجدول';
      case HandoverStatus.notStarted:
        return 'لم يبدأ';
      case HandoverStatus.inProgress:
        return 'لم يبدأ';
      case HandoverStatus.appointmentBooked:
        return 'تم حجز الموعد';
      case HandoverStatus.inspectionPending:
        return 'بانتظار المعاينة';
      case HandoverStatus.defectsSubmitted:
        return 'تم تقديم الملاحظات';
      case HandoverStatus.defectsFixing:
        return 'جاري الإصلاح';
      case HandoverStatus.readyForHandover:
        return 'جاهز للتسليم';
      case HandoverStatus.completed:
        return 'مكتمل';

      case HandoverStatus.cancelled:
        return 'ملغي';
    }
  }
}

class DefectItem extends Equatable {
  final String id;
  final String description;
  final String? location;
  final List<String> photos;
  final bool isFixed;
  final DateTime? fixedAt;

  String get title => description.length > 20
      ? '${description.substring(0, 20)}...'
      : description;

  const DefectItem({
    required this.id,
    required this.description,
    this.location,
    this.photos = const [],
    this.isFixed = false,
    this.fixedAt,
  });

  factory DefectItem.fromJson(Map<String, dynamic> json) {
    return DefectItem(
      id: json['id'] as String,
      description: json['description'] as String,
      location: json['location'] as String?,
      photos: json['photos'] != null
          ? List<String>.from(json['photos'] as List)
          : const [],
      isFixed: (json['is_fixed'] as bool?) ?? false,
      fixedAt: json['fixed_at'] != null
          ? DateTime.parse(json['fixed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'location': location,
      'photos': photos,
      'is_fixed': isFixed,
      'fixed_at': fixedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    description,
    location,
    photos,
    isFixed,
    fixedAt,
  ];
}

class HandoverModel extends Equatable {
  final String id;
  final String subscriptionId;
  final String userId;
  final String projectId;
  final String unitId;
  final HandoverStatus status;
  final DateTime? scheduledDate;
  final DateTime? actualDate;
  final String? inspectionNotes;
  final List<DefectItem> defects;
  final String? clientSignatureUrl;
  final String? adminSignatureUrl;
  final List<String> photos;
  final String? notes;
  final DateTime? inProgress;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HandoverModel({
    required this.id,
    required this.subscriptionId,
    required this.userId,
    required this.projectId,
    required this.unitId,
    this.status = HandoverStatus.scheduled,
    this.scheduledDate,
    this.actualDate,
    this.inspectionNotes,
    this.defects = const [],
    this.clientSignatureUrl,
    this.adminSignatureUrl,
    this.photos = const [],
    this.notes,
    this.completedAt,
    this.inProgress,
    required this.createdAt,
    required this.updatedAt,
  });

  int get totalDefects => defects.length;
  // Use defects.length as default for defectsCount if not tracked separately
  int get defectsCount => defects.length;
  int get defectsFixed => defects.where((d) => d.isFixed).length;
  int get pendingDefects => totalDefects - defectsFixed;

  factory HandoverModel.fromJson(Map<String, dynamic> json) {
    return HandoverModel(
      id: json['id'] as String,
      subscriptionId: json['subscription_id'] as String,
      userId: json['user_id'] as String,
      projectId: json['project_id'] as String,
      unitId: json['unit_id'] as String,
      status: json['status'] != null
          ? HandoverStatus.fromJson(json['status'] as String)
          : HandoverStatus.scheduled,
      scheduledDate: json['scheduled_date'] != null
          ? DateTime.parse(json['scheduled_date'] as String)
          : null,
      actualDate: json['actual_date'] != null
          ? DateTime.parse(json['actual_date'] as String)
          : null,
      inspectionNotes: json['inspection_notes'] as String?,
      defects: json['defects'] != null
          ? (json['defects'] as List)
                .map((e) => DefectItem.fromJson(e as Map<String, dynamic>))
                .toList()
          : const [],
      clientSignatureUrl: json['client_signature_url'] as String?,
      adminSignatureUrl: json['admin_signature_url'] as String?,
      photos: json['photos'] != null
          ? List<String>.from(json['photos'] as List)
          : const [],
      notes: json['notes'] as String?,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subscription_id': subscriptionId,
      'user_id': userId,
      'project_id': projectId,
      'unit_id': unitId,
      'status': status.toJson(),
      'scheduled_date': scheduledDate?.toIso8601String(),
      'defects': defects.map((e) => e.toJson()).toList(),
      'client_signature_url': clientSignatureUrl,
      'admin_signature_url': adminSignatureUrl,
      'photos': photos,
      'notes': notes,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  HandoverModel copyWith({
    String? id,
    String? subscriptionId,
    String? userId,
    String? projectId,
    String? unitId,
    HandoverStatus? status,
    DateTime? scheduledDate,
    List<DefectItem>? defects,
    String? clientSignatureUrl,
    String? adminSignatureUrl,
    List<String>? photos,
    String? notes,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HandoverModel(
      id: id ?? this.id,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      userId: userId ?? this.userId,
      projectId: projectId ?? this.projectId,
      unitId: unitId ?? this.unitId,
      status: status ?? this.status,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      defects: defects ?? this.defects,
      clientSignatureUrl: clientSignatureUrl ?? this.clientSignatureUrl,
      adminSignatureUrl: adminSignatureUrl ?? this.adminSignatureUrl,
      photos: photos ?? this.photos,
      notes: notes ?? this.notes,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    subscriptionId,
    userId,
    projectId,
    unitId,
    status,
    scheduledDate,
    defects,
    clientSignatureUrl,
    adminSignatureUrl,
    photos,
    notes,
    completedAt,
    createdAt,
    updatedAt,
  ];
}
