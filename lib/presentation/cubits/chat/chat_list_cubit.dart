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

  int get totalUnreadCount => unreadCounts.values.fold(0, (sum, count) => sum + count);

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
  StreamSubscription? _authSubscription;

  ChatListCubit({required ChatRepository chatRepository})
    : _chatRepository = chatRepository,
      super(ChatListInitial()) {
      // Listen to auth state changes to auto-reload chats on login
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        if (data.event == AuthChangeEvent.signedIn) {
          loadChats();
        } else if (data.event == AuthChangeEvent.signedOut) {
          emit(ChatListInitial());
          _chatsSubscription?.cancel();
        }
      });
  }

  Future<void> loadChats() async {
    try {
      emit(ChatListLoading());
      
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;

      if (currentUserId == null || currentUserId.isEmpty) {
        emit(ChatListError('User not logged in'));
        return;
      }

      // Fetch User Role
      String? role;
      try {
        final profileRes = await Supabase.instance.client
            .from('profiles')
            .select('role')
            .eq('id', currentUserId)
            .single();
        role = profileRes['role'];
      } catch (e) {
        debugPrint('Error fetching role in ChatListCubit: $e');
        // Fallback to 'user' if fails
        role = 'user';
      }

      final isAdmin = role == 'admin' || role == 'super_admin';

      _chatsSubscription?.cancel();
      
      Stream<List<ChatModel>> chatsStream;
      if (isAdmin) {
        chatsStream = _chatRepository.getAdminChatsStream(currentUserId);
      } else {
        chatsStream = _chatRepository.getUserChatsStream(currentUserId);
      }

      _chatsSubscription = chatsStream.listen(
            (chats) async {
              // Sort chats client-side to ensure immediate correctness
              chats.sort((a, b) {
                final dateA = a.lastMessageAt ?? a.createdAt;
                final dateB = b.lastMessageAt ?? b.createdAt;
                return dateB.compareTo(dateA); // Descending
              });

              // Emit initial state with empty unread counts to show data immediately
              if (state is ChatListLoaded) {
                 final currentState = state as ChatListLoaded;
                 emit(currentState.copyWith(chats: chats));
              } else {
                 emit(ChatListLoaded(chats: chats, unreadCounts: {}));
              }

              // Fetch unread counts asynchronously based on role
              try {
                Map<String, int> unreadCounts;
                if (isAdmin) {
                  unreadCounts = await _chatRepository.getUnreadCountsForAdmin(currentUserId);
                } else {
                  unreadCounts = await _chatRepository.getUnreadCountsForUser(currentUserId);
                }
                
                if (!isClosed && state is ChatListLoaded) {
                   final currentState = state as ChatListLoaded;
                   emit(currentState.copyWith(unreadCounts: unreadCounts));
                }
              } catch (e) {
                // Ignore error
                debugPrint('⚠️ Error fetching unread counts: $e');
              }
            },
            onError: (error) {
              debugPrint('❌ Error in chat stream: $error');
              if (!isClosed) emit(ChatListError('Failed to load chats: $error'));
            },
          );
    } catch (e) {
      if (!isClosed) emit(ChatListError('Error initializing chat list: $e'));
    }
  }

  void searchChats(String query) {
    if (state is ChatListLoaded) {
      final currentState = state as ChatListLoaded;
      emit(currentState.copyWith(searchQuery: query));
    }
  }

  void markChatAsRead(String chatId) {
    if (state is ChatListLoaded) {
      final currentState = state as ChatListLoaded;
      final updatedCounts = Map<String, int>.from(currentState.unreadCounts);
      updatedCounts[chatId] = 0;
      
      emit(currentState.copyWith(unreadCounts: updatedCounts));
    }
  }

  Future<void> refreshUnreadCounts() async {
      try {
        final currentUserId = Supabase.instance.client.auth.currentUser?.id;
        if (currentUserId == null) return;

        // Check role to determine which unread count method to use
        // We fetching it again to be safe, or we could rely on a cached value if we introduce one.
        // For robustness, let's quick-fetch or assume if we are in admin dashboard logic (but this is a generic cubit).
        final profileRes = await Supabase.instance.client
            .from('profiles')
            .select('role')
            .eq('id', currentUserId)
            .single();
        final role = profileRes['role'];
        final isAdmin = role == 'admin' || role == 'super_admin';

        Map<String, int> unreadCounts;
        if (isAdmin) {
          unreadCounts = await _chatRepository.getUnreadCountsForAdmin(currentUserId);
        } else {
          unreadCounts = await _chatRepository.getUnreadCountsForUser(
            currentUserId,
          );
        }
        
        if (state is ChatListLoaded) {
           final currentState = state as ChatListLoaded;
           emit(currentState.copyWith(unreadCounts: unreadCounts));
        }
      } catch (e) {
        debugPrint('Error refreshing unread counts: $e');
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
    _authSubscription?.cancel();
    return super.close();
  }
}
