import 'package:equatable/equatable.dart';
import 'package:mmm/data/models/user_model.dart';

enum MessageType {
  text,
  image,
  video,
  file,
  location;

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => MessageType.text,
    );
  }
}

class MessageModel extends Equatable {
  final String id;
  final String chatId;
  final String senderId;
  final String? content;
  final MessageType type;
  final String? mediaUrl;
  final String? fileName;
  final int? fileSize;
  final String? thumbnailUrl;
  final Map<String, dynamic>? mediaMetadata;
  final bool isRead;
  final DateTime? readAt;
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? parentMessageId;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Relations
  final UserModel? sender;

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.content,
    this.type = MessageType.text,
    this.mediaUrl,
    this.fileName,
    this.fileSize,
    this.thumbnailUrl,
    this.mediaMetadata,
    this.isRead = false,
    this.readAt,
    this.isDeleted = false,
    this.deletedAt,
    this.parentMessageId,
    required this.createdAt,
    required this.updatedAt,
    this.sender,
  });

  @override
  List<Object?> get props => [
        id,
        chatId,
        senderId,
        content,
        type,
        mediaUrl,
        fileName,
        fileSize,
        thumbnailUrl,
        mediaMetadata,
        isRead,
        readAt,
        isDeleted,
        deletedAt,
        parentMessageId,
        createdAt,
        updatedAt,
        sender,
      ];

  // Computed properties
  bool get hasMedia => mediaUrl != null && mediaUrl!.isNotEmpty;
  bool get isImage => type == MessageType.image;
  bool get isVideo => type == MessageType.video;
  bool get isFile => type == MessageType.file;
  bool get isLocation => type == MessageType.location;
  bool get isText => type == MessageType.text;
  bool get isEdited => updatedAt.difference(createdAt).inSeconds > 5 && !isDeleted;

  String get displayFileName => fileName ?? 'Unknown File';
  String get displayFileSize {
    if (fileSize == null) return '';
    final kb = fileSize! / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      chatId: json['chat_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String?,
      type: MessageType.fromString(json['message_type'] as String? ?? 'text'),
      mediaUrl: json['media_url'] as String?,
      fileName: json['file_name'] as String?,
      fileSize: json['file_size'] as int?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      mediaMetadata: json['media_metadata'] as Map<String, dynamic>?,
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      isDeleted: json['is_deleted'] as bool? ?? false,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      parentMessageId: json['parent_message_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      sender: json['profiles'] != null 
          ? UserModel.fromJson(json['profiles']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'content': content,
      'message_type': type.name,
      'media_url': mediaUrl,
      'file_name': fileName,
      'file_size': fileSize,
      'thumbnail_url': thumbnailUrl,
      'media_metadata': mediaMetadata,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'is_deleted': isDeleted,
      'deleted_at': deletedAt?.toIso8601String(),
      'parent_message_id': parentMessageId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? content,
    MessageType? type,
    String? mediaUrl,
    String? fileName,
    int? fileSize,
    String? thumbnailUrl,
    Map<String, dynamic>? mediaMetadata,
    bool? isRead,
    DateTime? readAt,
    bool? isDeleted,
    DateTime? deletedAt,
    String? parentMessageId,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserModel? sender,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      mediaMetadata: mediaMetadata ?? this.mediaMetadata,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      parentMessageId: parentMessageId ?? this.parentMessageId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sender: sender ?? this.sender,
    );
  }
}
