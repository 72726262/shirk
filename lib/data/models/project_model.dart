import 'package:equatable/equatable.dart';

enum ProjectStatus {
  planning,
  upcoming,
  inProgress,
  completed,
  soldOut,
  onHold,
  cancelled;

  String toJson() => name;

  static ProjectStatus fromJson(String value) {
    return ProjectStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ProjectStatus.planning,
    );
  }

  String get displayName {
    switch (this) {
      case ProjectStatus.planning:
        return 'التخطيط';
      case ProjectStatus.upcoming:
        return 'قريباً';
      case ProjectStatus.inProgress:
        return 'جاري التنفيذ';
      case ProjectStatus.completed:
        return 'مكتمل';
      case ProjectStatus.soldOut:
        return 'مباع بالكامل';
      case ProjectStatus.onHold:
        return 'متوقف مؤقتاً';
      case ProjectStatus.cancelled:
        return 'ملغي';
    }
  }
}

class ProjectModel extends Equatable {
  final String id;
  final String name;
  final String nameAr;
  final String? description;
  final String? descriptionAr;
  final ProjectStatus status;

  // Location
  final String? locationName;
  final double? locationLat;
  final double? locationLng;

  // Pricing
  final double? pricePerSqm;
  final double? minInvestment;
  final double? maxInvestment;
  final int totalUnits;
  final int soldUnits;
  final int reservedUnits;

  // Progress
  final double completionPercentage;
  final DateTime? startDate;
  final DateTime? expectedCompletionDate;
  final DateTime? actualCompletionDate;

  // Media
  final String? heroImageUrl;
  final String? videoUrl;
  final List<String> renderImages;

  // Partners
  final int totalPartners;

  // Metadata
  final bool featured;
  final bool isActive;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProjectModel({
    required this.id,
    required this.name,
    required this.nameAr,
    this.description,
    this.descriptionAr,
    this.status = ProjectStatus.upcoming,
    this.locationName,
    this.locationLat,
    this.locationLng,
    this.pricePerSqm,
    this.minInvestment,
    this.maxInvestment,
    this.totalUnits = 0,
    this.soldUnits = 0,
    this.reservedUnits = 0,
    this.completionPercentage = 0.0,
    this.startDate,
    this.expectedCompletionDate,
    this.actualCompletionDate,
    this.heroImageUrl,
    this.videoUrl,
    this.renderImages = const [],
    this.totalPartners = 0,
    this.featured = false,
    this.isActive = true,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  int get availableUnits => totalUnits - soldUnits - reservedUnits;

  // Compatibility getters for screens
  String get imageUrl => heroImageUrl ?? '';
  String get location => locationName ?? 'غير محدد';
  double get constructionProgress => completionPercentage;

  double get totalValue => (pricePerSqm ?? 0) * totalUnits.toDouble();
  int get unitsCount => totalUnits;
  String get developer => 'شريك'; // Default developer name

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as String,
      name: json['name'] as String,
      nameAr: json['name_ar'] as String,
      description: json['description'] as String?,
      descriptionAr: json['description_ar'] as String?,
      status: json['status'] != null
          ? ProjectStatus.fromJson(json['status'] as String)
          : ProjectStatus.upcoming,
      locationName: json['location_name'] as String?,
      locationLat: json['location_lat'] != null
          ? (json['location_lat'] as num).toDouble()
          : null,
      locationLng: json['location_lng'] != null
          ? (json['location_lng'] as num).toDouble()
          : null,
      pricePerSqm: json['price_per_sqm'] != null
          ? (json['price_per_sqm'] as num).toDouble()
          : null,
      minInvestment: json['min_investment'] != null
          ? (json['min_investment'] as num).toDouble()
          : null,
      maxInvestment: json['max_investment'] != null
          ? (json['max_investment'] as num).toDouble()
          : null,
      totalUnits: (json['total_units'] as num?)?.toInt() ?? 0,
      soldUnits: (json['sold_units'] as num?)?.toInt() ?? 0,
      reservedUnits: (json['reserved_units'] as num?)?.toInt() ?? 0,
      completionPercentage:
          (json['completion_percentage'] as num?)?.toDouble() ?? 0.0,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      expectedCompletionDate: json['expected_completion_date'] != null
          ? DateTime.parse(json['expected_completion_date'] as String)
          : null,
      actualCompletionDate: json['actual_completion_date'] != null
          ? DateTime.parse(json['actual_completion_date'] as String)
          : null,
      heroImageUrl: json['hero_image_url'] as String?,
      videoUrl: json['video_url'] as String?,
      renderImages: json['render_images'] != null
          ? List<String>.from(json['render_images'] as List)
          : const [],
      totalPartners: (json['total_partners'] as num?)?.toInt() ?? 0,
      featured: (json['featured'] as bool?) ?? false,
      isActive: (json['is_active'] as bool?) ?? true,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_ar': nameAr,
      'description': description,
      'description_ar': descriptionAr,
      'status': status.toJson(),
      'location_name': locationName,
      'location_lat': locationLat,
      'location_lng': locationLng,
      'price_per_sqm': pricePerSqm,
      'min_investment': minInvestment,
      'max_investment': maxInvestment,
      'total_units': totalUnits,
      'sold_units': soldUnits,
      'reserved_units': reservedUnits,
      'completion_percentage': completionPercentage,
      'start_date': startDate?.toIso8601String(),
      'expected_completion_date': expectedCompletionDate?.toIso8601String(),
      'actual_completion_date': actualCompletionDate?.toIso8601String(),
      'hero_image_url': heroImageUrl,
      'video_url': videoUrl,
      'render_images': renderImages,
      'total_partners': totalPartners,
      'featured': featured,
      'is_active': isActive,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ProjectModel copyWith({
    String? id,
    String? name,
    String? nameAr,
    String? description,
    String? descriptionAr,
    ProjectStatus? status,
    String? locationName,
    double? locationLat,
    double? locationLng,
    double? pricePerSqm,
    double? minInvestment,
    double? maxInvestment,
    int? totalUnits,
    int? soldUnits,
    int? reservedUnits,
    double? completionPercentage,
    DateTime? startDate,
    DateTime? expectedCompletionDate,
    DateTime? actualCompletionDate,
    String? heroImageUrl,
    String? videoUrl,
    List<String>? renderImages,
    int? totalPartners,
    bool? featured,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      description: description ?? this.description,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      status: status ?? this.status,
      locationName: locationName ?? this.locationName,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
      pricePerSqm: pricePerSqm ?? this.pricePerSqm,
      minInvestment: minInvestment ?? this.minInvestment,
      maxInvestment: maxInvestment ?? this.maxInvestment,
      totalUnits: totalUnits ?? this.totalUnits,
      soldUnits: soldUnits ?? this.soldUnits,
      reservedUnits: reservedUnits ?? this.reservedUnits,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      startDate: startDate ?? this.startDate,
      expectedCompletionDate:
          expectedCompletionDate ?? this.expectedCompletionDate,
      actualCompletionDate: actualCompletionDate ?? this.actualCompletionDate,
      heroImageUrl: heroImageUrl ?? this.heroImageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      renderImages: renderImages ?? this.renderImages,
      totalPartners: totalPartners ?? this.totalPartners,
      featured: featured ?? this.featured,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    nameAr,
    description,
    descriptionAr,
    status,
    locationName,
    locationLat,
    locationLng,
    pricePerSqm,
    minInvestment,
    maxInvestment,
    totalUnits,
    soldUnits,
    reservedUnits,
    completionPercentage,
    startDate,
    expectedCompletionDate,
    actualCompletionDate,
    heroImageUrl,
    videoUrl,
    renderImages,
    totalPartners,
    featured,
    isActive,
    createdBy,
    createdAt,
    updatedAt,
  ];
}
