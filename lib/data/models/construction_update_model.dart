import 'package:equatable/equatable.dart';

enum UpdateType {
  progress,
  milestone,
  delay,
  completion;

  String toJson() => name;
  
  static UpdateType fromJson(String value) {
    return UpdateType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UpdateType.progress,
    );
  }
  
  String get displayName {
    switch (this) {
      case UpdateType.progress:
        return 'تقدم';
      case UpdateType.milestone:
        return 'إنجاز مهم';
      case UpdateType.delay:
        return 'تأخير';
      case UpdateType.completion:
        return 'اكتمال';
    }
  }
}

class ConstructionUpdateModel extends Equatable {
  final String id;
  final String projectId;
  final String title;
  final String? titleAr;
  final String? description;
  final String? descriptionAr;
  final UpdateType type;
  final double? progressPercentage;
  final List<String> photos;
  final List<String> videos;
  final String? reportUrl;
  final String? postedBy;
  final DateTime createdAt;

  const ConstructionUpdateModel({
    required this.id,
    required this.projectId,
    required this.title,
    this.titleAr,
    this.description,
    this.descriptionAr,
    this.type = UpdateType.progress,
    this.progressPercentage,
    this.photos = const [],
    this.videos = const [],
    this.reportUrl,
    this.postedBy,
    required this.createdAt,
  });

  String get displayTitle => titleAr ?? title;
  String? get displayDescription => descriptionAr ?? description;
  double get progress => (progressPercentage ?? 0.0) / 100.0;

  factory ConstructionUpdateModel.fromJson(Map<String, dynamic> json) {
    return ConstructionUpdateModel(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      title: json['title'] as String,
      titleAr: json['title_ar'] as String?,
      description: json['description'] as String?,
      descriptionAr: json['description_ar'] as String?,
      type: json['type'] != null
          ? UpdateType.fromJson(json['type'] as String)
          : UpdateType.progress,
      progressPercentage: json['progress_percentage'] != null
          ? (json['progress_percentage'] as num).toDouble()
          : null,
      photos: json['photos'] != null
          ? List<String>.from(json['photos'] as List)
          : const [],
      videos: json['videos'] != null
          ? List<String>.from(json['videos'] as List)
          : const [],
      reportUrl: json['report_url'] as String?,
      postedBy: json['posted_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'title': title,
      'title_ar': titleAr,
      'description': description,
      'description_ar': descriptionAr,
      'type': type.toJson(),
      'progress_percentage': progressPercentage,
      'photos': photos,
      'videos': videos,
      'report_url': reportUrl,
      'posted_by': postedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ConstructionUpdateModel copyWith({
    String? id,
    String? projectId,
    String? title,
    String? titleAr,
    String? description,
    String? descriptionAr,
    UpdateType? type,
    double? progressPercentage,
    List<String>? photos,
    List<String>? videos,
    String? reportUrl,
    String? postedBy,
    DateTime? createdAt,
  }) {
    return ConstructionUpdateModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      titleAr: titleAr ?? this.titleAr,
      description: description ?? this.description,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      type: type ?? this.type,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      photos: photos ?? this.photos,
      videos: videos ?? this.videos,
      reportUrl: reportUrl ?? this.reportUrl,
      postedBy: postedBy ?? this.postedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        title,
        titleAr,
        description,
        descriptionAr,
        type,
        progressPercentage,
        photos,
        videos,
        reportUrl,
        postedBy,
        createdAt,
      ];
}
