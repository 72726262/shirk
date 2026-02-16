import 'dart:async';
import 'dart:io';
import 'package:mmm/data/models/message_model.dart';
import 'package:mmm/data/services/chat_storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessageRepository {
  final SupabaseClient _client;
  final ChatStorageService _storageService;

  MessageRepository({
    SupabaseClient? client,
    ChatStorageService? storageService,
  }) : _client = client ?? Supabase.instance.client,
       _storageService = storageService ?? ChatStorageService();

  /// Get messages stream for a chat
  /// Fetches messages with sender details and updates in real-time
  Stream<List<MessageModel>> getChatMessagesStream(String chatId) {
    final controller = StreamController<List<MessageModel>>();

    // Initial Fetch
    void fetchMessages() async {
      try {
        final data = await _client
            .from('messages')
            .select('*, profiles(*)') // Fetch sender profile relations
            .eq('chat_id', chatId)
            .order('created_at', ascending: true); // Latest at bottom

        final messages = (data as List)
            .map((json) => MessageModel.fromJson(json))
            .where((msg) => !msg.isDeleted)
            .toList();

        if (!controller.isClosed) controller.add(messages);
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    fetchMessages();

    // Real-time subscription
    final subscription = _client
        .channel('public:messages:$chatId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: chatId,
          ),
          callback: (_) => fetchMessages(),
        )
        .subscribe();

    controller.onCancel = () {
      subscription.unsubscribe();
      controller.close();
    };

    return controller.stream;
  }

  /// Send text message
  Future<MessageModel> sendTextMessage({
    required String chatId,
    required String senderId,
    required String content,
    String? parentMessageId,
  }) async {
    try {
      final response = await _client
          .from('messages')
          .insert({
            'chat_id': chatId,
            'sender_id': senderId,
            'content': content,
            'message_type': 'text',
            'parent_message_id': parentMessageId,
          })
          .select()
          .single();

      final msgModel = MessageModel.fromJson(response);
      
      // Update chat timestamp
      await _updateChatLastMessage(chatId);

      return msgModel;
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Send image message
  Future<MessageModel> sendImageMessage({
    required String chatId,
    required String senderId,
    required File imageFile,
    String? caption,
    Function(double)? onProgress,
  }) async {
    try {
      // Upload image
      final uploadData = await _storageService.uploadImage(
        imageFile: imageFile,
        chatId: chatId,
        userId: senderId,
        onProgress: onProgress,
      );

      // Create message
      final response = await _client
          .from('messages')
          .insert({
            'chat_id': chatId,
            'sender_id': senderId,
            'content': caption,
            'message_type': 'image',
            'media_url': uploadData['media_url'],
            'file_name': uploadData['file_name'],
            'file_size': uploadData['file_size'],
            'media_metadata': uploadData['media_metadata'],
          })
          .select()
          .single();

      return MessageModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to send image: $e');
    }
  }

  /// Send video message
  Future<MessageModel> sendVideoMessage({
    required String chatId,
    required String senderId,
    required File videoFile,
    File? thumbnailFile,
    String? caption,
    Function(double)? onProgress,
  }) async {
    try {
      // Upload video
      final uploadData = await _storageService.uploadVideo(
        videoFile: videoFile,
        chatId: chatId,
        userId: senderId,
        thumbnailFile: thumbnailFile,
        onProgress: onProgress,
      );

      // Create message
      final response = await _client
          .from('messages')
          .insert({
            'chat_id': chatId,
            'sender_id': senderId,
            'content': caption,
            'message_type': 'video',
            'media_url': uploadData['media_url'],
            'file_name': uploadData['file_name'],
            'file_size': uploadData['file_size'],
            'thumbnail_url': uploadData['thumbnail_url'],
            'media_metadata': uploadData['media_metadata'],
          })
          .select()
          .single();

      return MessageModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to send video: $e');
    }
  }

  /// Send file message
  Future<MessageModel> sendFileMessage({
    required String chatId,
    required String senderId,
    required File file,
    String? caption,
    Function(double)? onProgress,
  }) async {
    try {
      // Upload file
      final uploadData = await _storageService.uploadFile(
        file: file,
        chatId: chatId,
        userId: senderId,
        onProgress: onProgress,
      );

      // Create message
      final response = await _client
          .from('messages')
          .insert({
            'chat_id': chatId,
            'sender_id': senderId,
            'content': caption,
            'message_type': 'file',
            'media_url': uploadData['media_url'],
            'file_name': uploadData['file_name'],
            'file_size': uploadData['file_size'],
            'media_metadata': uploadData['media_metadata'],
          })
          .select()
          .single();

      // Update chat timestamp
      await _updateChatLastMessage(chatId);

      return MessageModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to send file: $e');
    }
  }

  /// Update chat's last_message_at
  Future<void> _updateChatLastMessage(String chatId) async {
    try {
      await _client
          .from('chats')
          .update({
            'last_message_at': DateTime.now().toIso8601String(),
          })
          .eq('id', chatId);
    } catch (e) {
      print('Failed to update chat timestamp: $e');
      // Don't throw, as the message was likely sent successfully
    }
  }

  /// Delete message (soft delete)
  Future<void> deleteMessage(String messageId, String userId) async {
    try {
      // Get message to check for media
      final message = await _client
          .from('messages')
          .select()
          .eq('id', messageId)
          .single();

      final msg = MessageModel.fromJson(message);

      // Verify sender
      if (msg.senderId != userId) {
        throw Exception('Cannot delete message from another user');
      }

      // Soft delete message
      await _client
          .from('messages')
          .update({
            'is_deleted': true,
            'deleted_at': DateTime.now().toIso8601String(),
          })
          .eq('id', messageId);

      // We keep the media file for now as it might be referenced elsewhere
      // or we can delete it if strict cleanup is needed
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  /// Edit message
  Future<void> editMessage(
    String messageId,
    String userId,
    String newContent,
  ) async {
    try {
      await _client
          .from('messages')
          .update({
            'content': newContent,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', messageId)
          .eq('sender_id', userId);
    } catch (e) {
      throw Exception('Failed to edit message: $e');
    }
  }

  /// Mark message as read
  Future<void> markAsRead(String messageId) async {
    try {
      await _client
          .from('messages')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', messageId);
    } catch (e) {
      throw Exception('Failed to mark as read: $e');
    }
  }

  /// Mark multiple messages as read (Bulk)
  Future<void> markMessagesAsRead(List<String> messageIds) async {
    if (messageIds.isEmpty) return;
    try {
      await _client
          .from('messages')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .inFilter('id', messageIds);
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  /// Get unread count for a chat
  Future<int> getUnreadCount(String chatId, String userId) async {
    try {
      final response = await _client
          .from('messages')
          .select('id')
          .eq('chat_id', chatId)
          .neq('sender_id', userId)
          .eq('is_read', false)
          .eq('is_deleted', false);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }
}
