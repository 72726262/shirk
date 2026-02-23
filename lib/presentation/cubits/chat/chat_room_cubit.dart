import 'dart:async';
import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart'; // Add this for debugPrint
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/data/models/message_model.dart';
import 'package:mmm/data/repositories/message_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// States
abstract class ChatRoomState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ChatRoomInitial extends ChatRoomState {}

class ChatRoomLoading extends ChatRoomState {}

class ChatRoomLoaded extends ChatRoomState {
  final List<MessageModel> messages;
  final bool isSending;
  final double uploadProgress;

  ChatRoomLoaded({
    required this.messages,
    this.isSending = false,
    this.uploadProgress = 0.0,
  });

  @override
  List<Object?> get props => [messages, isSending, uploadProgress];

  ChatRoomLoaded copyWith({
    List<MessageModel>? messages,
    bool? isSending,
    double? uploadProgress,
  }) {
    return ChatRoomLoaded(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }
}

class ChatRoomError extends ChatRoomState {
  final String message;

  ChatRoomError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class ChatRoomCubit extends Cubit<ChatRoomState> {
  final MessageRepository _messageRepository;
  final String chatId;
  StreamSubscription? _messagesSubscription;
  final String _currentUserId;

  ChatRoomCubit({
    required MessageRepository messageRepository,
    required this.chatId,
  }) : _messageRepository = messageRepository,
       _currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '',
       super(ChatRoomInitial());

  void loadMessages() {
    try {
      emit(ChatRoomLoading());

      _messagesSubscription?.cancel();
      _messagesSubscription = _messageRepository
          .getChatMessagesStream(chatId)
          .listen(
            (messages) {
              // Mark relevant messages as read
              _markMessagesAsRead(messages);

              if (state is ChatRoomLoaded) {
                final currentState = state as ChatRoomLoaded;
                emit(currentState.copyWith(messages: messages));
              } else {
                emit(ChatRoomLoaded(messages: messages));
              }
            },
            onError: (error) {
              if (!isClosed) {
                emit(ChatRoomError('Failed to load messages: $error'));
              }
            },
          );
    } catch (e) {
      emit(ChatRoomError('Error initializing chat room: $e'));
    }
  }

  Future<void> _markMessagesAsRead(List<MessageModel> messages) async {
    final unreadMessageIds = messages
        .where((m) => !m.isRead && m.senderId != _currentUserId)
        .map((m) => m.id)
        .toList();

    if (unreadMessageIds.isNotEmpty) {
      try {
        await _messageRepository.markMessagesAsRead(unreadMessageIds);
      } catch (e) {
        debugPrint('Error marking messages as read: $e');
      }
    }
  }

  Future<void> sendTextMessage(String content) async {
    if (content.trim().isEmpty) return;

    if (state is ChatRoomLoaded) {
      final currentState = state as ChatRoomLoaded;
      
      // Proactively mark existing unread messages as read when sending
      // This handles the case where the user entered the chat but the initial mark-as-read failed
      _markMessagesAsRead(currentState.messages);

      // Optimistic Update
      final tempMessage = MessageModel(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        chatId: chatId,
        senderId: _currentUserId,
        content: content,
        type: MessageType.text,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isRead: false,
        isDeleted: false,
      );

      final optimisticMessages = [...currentState.messages, tempMessage];
      emit(
        currentState.copyWith(messages: optimisticMessages, isSending: true),
      );

      try {
        final sentMessage = await _messageRepository.sendTextMessage(
          chatId: chatId,
          senderId: _currentUserId,
          content: content,
        );

        // Replace temp message with actual one (though stream might have done it)
        // We defer to the stream usually, but to be safe:
        if (state is ChatRoomLoaded) {
          final currentMsgs = (state as ChatRoomLoaded).messages;
          final updatedMsgs = currentMsgs
              .map((m) => m.id == tempMessage.id ? sentMessage : m)
              .toList();
          // Determine if stream already added it?
          // If stream is fast, we might have duplicates if we aren't careful.
          // But since stream replaces the whole list usually in our repo logic (fetchMessages),
          // the stream update will overwrite our optimistic state eventually.
          // So for now, simply stop sending loading.
          if (!isClosed) {
            emit((state as ChatRoomLoaded).copyWith(isSending: false));
          }
        }
      } catch (e) {
        if (!isClosed) emit(ChatRoomError('Failed to send message: $e'));
        if (!isClosed) loadMessages();
      }
    }
  }

  Future<void> sendImageMessage(
    Uint8List bytes, {
    required String fileName,
    String? caption,
  }) async {
    if (state is ChatRoomLoaded) {
      final currentState = state as ChatRoomLoaded;
      emit(currentState.copyWith(isSending: true, uploadProgress: 0.0));

      try {
        await _messageRepository.sendImageMessage(
          chatId: chatId,
          senderId: _currentUserId,
          imageBytes: bytes,
          fileName: fileName,
          caption: caption,
          onProgress: (progress) {
            if (state is ChatRoomLoaded && !isClosed) {
              emit(
                (state as ChatRoomLoaded).copyWith(uploadProgress: progress),
              );
            }
          },
        );
        if (!isClosed) {
          emit(currentState.copyWith(isSending: false, uploadProgress: 0.0));
        }
      } catch (e) {
        print(e.toString());
        if (!isClosed) {
          emit(ChatRoomError('فشل إرسال الصورة: $e'));
          loadMessages();
        }
      }
    }
  }

  Future<void> sendVideoMessage(
    Uint8List videoBytes, {
    required String fileName,
    String? caption,
  }) async {
    if (state is ChatRoomLoaded) {
      final currentState = state as ChatRoomLoaded;
      emit(currentState.copyWith(isSending: true, uploadProgress: 0.0));

      try {
        await _messageRepository.sendVideoMessage(
          chatId: chatId,
          senderId: _currentUserId,
          videoBytes: videoBytes,
          fileName: fileName,
          caption: caption,
          onProgress: (progress) {
            if (state is ChatRoomLoaded && !isClosed) {
              emit(
                (state as ChatRoomLoaded).copyWith(uploadProgress: progress),
              );
            }
          },
        );
        if (!isClosed) {
          emit(currentState.copyWith(isSending: false, uploadProgress: 0.0));
        }
      } catch (e) {
        if (!isClosed) {
          emit(ChatRoomError('فشل إرسال الفيديو: $e'));
          loadMessages();
        }
      }
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _messageRepository.deleteMessage(messageId, _currentUserId);
      // The stream will automatically update the UI
    } catch (e) {
      if (!isClosed) {
        emit(ChatRoomError('Failed to delete message: $e'));
        loadMessages(); // Refresh state
      }
    }
  }

  Future<void> editMessage(String messageId, String newContent) async {
    if (newContent.trim().isEmpty) return;
    try {
      await _messageRepository.editMessage(
        messageId,
        _currentUserId,
        newContent,
      );
      // The stream will automatically update the UI
    } catch (e) {
      if (!isClosed) {
        emit(ChatRoomError('Failed to edit message: $e'));
        loadMessages(); // Refresh state
      }
    }
  }

  Future<void> sendFileMessage(
    Uint8List fileBytes, {
    required String fileName,
    String? caption,
  }) async {
    if (state is ChatRoomLoaded) {
      final currentState = state as ChatRoomLoaded;
      emit(currentState.copyWith(isSending: true, uploadProgress: 0.0));

      try {
        await _messageRepository.sendFileMessage(
          chatId: chatId,
          senderId: _currentUserId,
          fileBytes: fileBytes,
          fileName: fileName,
          caption: caption,
          onProgress: (progress) {
            if (state is ChatRoomLoaded && !isClosed) {
              emit(
                (state as ChatRoomLoaded).copyWith(uploadProgress: progress),
              );
            }
          },
        );
        if (!isClosed) {
          emit(currentState.copyWith(isSending: false, uploadProgress: 0.0));
        }
      } catch (e) {
        if (!isClosed) {
          emit(ChatRoomError('فشل إرسال الملف: $e'));
          loadMessages();
        }
      }
    }
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }
}
