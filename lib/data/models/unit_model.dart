import 'package:equatable/equatable.dart';

enum UnitStatus {
  available,
  reserved,
  sold,
  blocked;

  String toJson() => name;
  
  static UnitStatus fromJson(String value) {
    return UnitStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UnitStatus.available,
    );
  }
  
  String get displayName {
    switch (this) {
      case UnitStatus.available:
        return 'متاح';
      case UnitStatus.reserved:
        return 'محجوز';
      case UnitStatus.sold:
        return 'مباع';
      case UnitStatus.blocked:
        return 'محظور';
    }
  }
}

enum UnitType {
  apartment,
  villa,
  shop,
  office,
  land;

  String toJson() => name;
  
  static UnitType fromJson(String value) {
    return UnitType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UnitType.apartment,
    );
  }
  
  String get displayName {
    switch (this) {
      case UnitType.apartment:
        return 'شقة';
      case UnitType.villa:
        return 'فيلا';
      case UnitType.shop:
        return 'محل';
      case UnitType.office:
        return 'مكتب';
      case UnitType.land:
        return 'أرض';
    }
  }
}

class UnitModel extends Equatable {
  final String id;
  final String projectId;
  final String unitNumber;
  final int? floor;
  final double areaSqm;
  final double price;
  final UnitStatus status;
  final UnitType? unitType;
  final int? bedrooms;
  final int? bathrooms;
  final List<String> features;
  final String? floorPlanUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UnitModel({
    required this.id,
    required this.projectId,
    required this.unitNumber,
    this.floor,
    required this.areaSqm,
    required this.price,
    this.status = UnitStatus.available,
    this.unitType,
    this.bedrooms,
    this.bathrooms,
    this.features = const [],
    this.floorPlanUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    return UnitModel(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      unitNumber: json['unit_number'] as String,
      floor: json['floor'] as int?,
      areaSqm: (json['area_sqm'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      status: json['status'] != null
          ? UnitStatus.fromJson(json['status'] as String)
          : UnitStatus.available,
      unitType: json['unit_type'] != null
          ? UnitType.fromJson(json['unit_type'] as String)
          : null,
      bedrooms: json['bedrooms'] as int?,
      bathrooms: json['bathrooms'] as int?,
      features: json['features'] != null
          ? List<String>.from(json['features'] as List)
          : const [],
      floorPlanUrl: json['floor_plan_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'unit_number': unitNumber,
      'floor': floor,
      'area_sqm': areaSqm,
      'price': price,
      'status': status.toJson(),
      'unit_type': unitType?.toJson(),
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'features': features,
      'floor_plan_url': floorPlanUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UnitModel copyWith({
    String? id,
    String? projectId,
    String? unitNumber,
    int? floor,
    double? areaSqm,
    double? price,
    UnitStatus? status,
    UnitType? unitType,
    int? bedrooms,
    int? bathrooms,
    List<String>? features,
    String? floorPlanUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UnitModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      unitNumber: unitNumber ?? this.unitNumber,
      floor: floor ?? this.floor,
      areaSqm: areaSqm ?? this.areaSqm,
      price: price ?? this.price,
      status: status ?? this.status,
      unitType: unitType ?? this.unitType,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      features: features ?? this.features,
      floorPlanUrl: floorPlanUrl ?? this.floorPlanUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        unitNumber,
        floor,
        areaSqm,
        price,
        status,
        unitType,
        bedrooms,
        bathrooms,
        features,
        floorPlanUrl,
        createdAt,
        updatedAt,
      ];
}
