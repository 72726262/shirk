import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/data/models/chat_model.dart';
import 'package:mmm/data/repositories/chat_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// States
abstract class ChatListState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ChatListInitial extends ChatListState {}

class ChatListLoading extends ChatListState {}

class ChatListLoaded extends ChatListState {
  final List<ChatModel> chats;
  final Map<String, int> unreadCounts;
  final String searchQuery;

  ChatListLoaded({
    required this.chats,
    required this.unreadCounts,
    this.searchQuery = '',
  });

  List<ChatModel> get filteredChats {
    if (searchQuery.isEmpty) return chats;
    return chats.where((chat) {
      final title = chat.title?.toLowerCase() ?? '';
      return title.contains(searchQuery.toLowerCase());
    }).toList();
  }

  @override
  List<Object?> get props => [chats, unreadCounts, searchQuery];

  ChatListLoaded copyWith({
    List<ChatModel>? chats,
    Map<String, int>? unreadCounts,
    String? searchQuery,
  }) {
    return ChatListLoaded(
      chats: chats ?? this.chats,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class ChatListError extends ChatListState {
  final String message;

  ChatListError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class ChatListCubit extends Cubit<ChatListState> {
  final ChatRepository _chatRepository;
  StreamSubscription? _chatsSubscription;
  final String _currentUserId;

  ChatListCubit({required ChatRepository chatRepository})
    : _chatRepository = chatRepository,
      _currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '',
      super(ChatListInitial());

  void loadChats() {
    try {
      emit(ChatListLoading());

      if (_currentUserId.isEmpty) {
        emit(ChatListError('User not logged in'));
        return;
      }

      _chatsSubscription?.cancel();
      _chatsSubscription = _chatRepository
          .getUserChatsStream(_currentUserId)
          .listen(
            (chats) async {
              // Fetch unread counts for all chats
              final unreadCounts = await _chatRepository.getUnreadCountsForUser(
                _currentUserId,
              );

              // Sort chats client-side to ensure immediate correctness
              chats.sort((a, b) {
                final dateA = a.lastMessageAt ?? a.createdAt;
                final dateB = b.lastMessageAt ?? b.createdAt;
                return dateB.compareTo(dateA); // Descending
              });

              if (state is ChatListLoaded) {
                final currentState = state as ChatListLoaded;
                emit(
                  currentState.copyWith(
                    chats: chats,
                    unreadCounts: unreadCounts,
                  ),
                );
              } else {
                emit(ChatListLoaded(chats: chats, unreadCounts: unreadCounts));
              }
            },
            onError: (error) {
              emit(ChatListError('Failed to load chats: $error'));
            },
          );
    } catch (e) {
      emit(ChatListError('Error initializing chat list: $e'));
    }
  }

  void searchChats(String query) {
    if (state is ChatListLoaded) {
      final currentState = state as ChatListLoaded;
      emit(currentState.copyWith(searchQuery: query));
    }
  }

  Future<void> refreshUnreadCounts() async {
    if (state is ChatListLoaded) {
      final currentState = state as ChatListLoaded;
      try {
        final unreadCounts = await _chatRepository.getUnreadCountsForUser(
          _currentUserId,
        );
        emit(currentState.copyWith(unreadCounts: unreadCounts));
      } catch (e) {
        // Silently fail for unread counts refresh
        // print('Error refreshing unread counts: $e');
      }
    }
  }

  Future<void> deleteChat(String chatId) async {
    try {
      await _chatRepository.deleteChat(chatId);
      // Force refresh to remove the chat immediately from UI
      loadChats();
    } catch (e) {
      debugPrint('Error deleting chat: $e');
      emit(ChatListError('فشل حذف المحادثة: $e'));
      // Reload to restore state if needed
      loadChats();
    }
  }

  @override
  Future<void> close() {
    _chatsSubscription?.cancel();
    return super.close();
  }
}
