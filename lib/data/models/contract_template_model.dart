import 'package:equatable/equatable.dart';

enum ContractTemplateType {
  subscription,
  handover,
  payment,
  other,
}

class ContractTemplateModel extends Equatable {
  final String id;
  final String name;
  final String nameAr;
  final ContractTemplateType templateType;
  final String content;
  final String contentAr;
  final String version;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ContractTemplateModel({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.templateType,
    required this.content,
    required this.contentAr,
    this.version = '1.0',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ContractTemplateModel.fromJson(Map<String, dynamic> json) {
    return ContractTemplateModel(
      id: json['id'] as String,
      name: json['name'] as String,
      nameAr: json['name_ar'] as String,
      templateType: ContractTemplateType.values.firstWhere(
        (e) => e.name == json['template_type'],
        orElse: () => ContractTemplateType.other,
      ),
      content: json['content'] as String,
      contentAr: json['content_ar'] as String,
      version: json['version'] as String? ?? '1.0',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_ar': nameAr,
      'template_type': templateType.name,
      'content': content,
      'content_ar': contentAr,
      'version': version,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        nameAr,
        templateType,
        content,
        contentAr,
        version,
        isActive,
        createdAt,
        updatedAt,
      ];
}
