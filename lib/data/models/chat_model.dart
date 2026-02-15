import 'package:equatable/equatable.dart';
import 'package:mmm/data/models/user_model.dart';
import 'package:mmm/data/models/message_model.dart';

enum ChatType {
  private,
  group,
  support;

  static ChatType fromString(String value) {
    return ChatType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => ChatType.private,
    );
  }
}

class ChatModel extends Equatable {
  final String id;
  final ChatType type;
  final String? title;
  final String? description;
  final String? avatarUrl;
  final String? createdBy;
  final String? lastMessageId;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Relations - Not stored in DB directly, but populated from joins
  final List<UserModel> members;
  final MessageModel? lastMessage;
  final int unreadCount;

  const ChatModel({
    required this.id,
    this.type = ChatType.private,
    this.title,
    this.description,
    this.avatarUrl,
    this.createdBy,
    this.lastMessageId,
    this.lastMessageAt,
    required this.createdAt,
    required this.updatedAt,
    this.members = const [],
    this.lastMessage,
    this.unreadCount = 0,
  });

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        description,
        avatarUrl,
        createdBy,
        lastMessageId,
        lastMessageAt,
        createdAt,
        updatedAt,
        members,
        lastMessage,
        unreadCount,
      ];

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    // Parse members if available
    List<UserModel> parsedMembers = [];
    if (json['chat_members'] != null && json['chat_members'] is List) {
      for (var member in json['chat_members']) {
        if (member['profiles'] != null) {
          parsedMembers.add(UserModel.fromJson(member['profiles']));
        }
      }
    }

    // Parse last message if available
    MessageModel? parsedLastMessage;
    if (json['messages'] != null) {
      if (json['messages'] is List && (json['messages'] as List).isNotEmpty) {
        parsedLastMessage = MessageModel.fromJson(json['messages'][0]);
      } else if (json['messages'] is Map) {
         parsedLastMessage = MessageModel.fromJson(json['messages']);
      }
    }

    return ChatModel(
      id: json['id'] as String,
      type: ChatType.fromString(json['chat_type'] as String? ?? 'private'),
      title: json['title'] as String?,
      description: json['description'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdBy: json['created_by'] as String?,
      lastMessageId: json['last_message_id'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      members: parsedMembers,
      lastMessage: parsedLastMessage,
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_type': type.name,
      'title': title,
      'description': description,
      'avatar_url': avatarUrl,
      'created_by': createdBy,
      'last_message_id': lastMessageId,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      // Relations are usually not sent back to storage via toJson of the parent
    };
  }

  ChatModel copyWith({
    String? id,
    ChatType? type,
    String? title,
    String? description,
    String? avatarUrl,
    String? createdBy,
    String? lastMessageId,
    DateTime? lastMessageAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<UserModel>? members,
    MessageModel? lastMessage,
    int? unreadCount,
  }) {
    return ChatModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdBy: createdBy ?? this.createdBy,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      members: members ?? this.members,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
