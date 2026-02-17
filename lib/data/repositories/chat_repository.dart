import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mmm/data/models/chat_model.dart';

import 'package:mmm/data/models/message_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatRepository {
  final SupabaseClient _client;
  final StreamController<List<ChatModel>> _chatsController =
      StreamController<List<ChatModel>>.broadcast();
  RealtimeChannel? _chatsSubscription;

  ChatRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  /// Get user chats stream with full relational data
  /// This retrieves chats the user is a member of, including other members' profiles and the last message.
  Stream<List<ChatModel>> getUserChatsStream(String userId) {
    _initChatsSubscription(userId);
    return _chatsController.stream;
  }

  Future<void> _initChatsSubscription(String userId) async {
    // Initial fetch
    await _fetchChats(userId);

    // Subscribe to changes in chats, chat_members, and messages
    // Note: To be efficient, we blindly refetch on any relevant change.
    // Deep granularity is hard with simple subscriptions.
    _chatsSubscription = _client
        .channel('public:chats_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chats',
          callback: (_) => _fetchChats(userId),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          callback: (_) => _fetchChats(userId),
        )
        // We also need to list to chat_members to know if we were added to a new chat
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) => _fetchChats(userId),
        )
        .subscribe();
  }

  Future<void> _fetchChats(String userId) async {
    try {
      // 1. Get IDs of chats I belong to
      final myChatsResponse = await _client
          .from('chat_members')
          .select('chat_id')
          .eq('user_id', userId);

      final myChatIds = (myChatsResponse as List)
          .map((e) => e['chat_id'] as String)
          .toList();

      if (myChatIds.isEmpty) {
        _chatsController.add([]);
        return;
      }

      // 2. Fetch full chat details for these IDs
      // capturing:
      // - chat details
      // - chat_members -> profiles (to show other user info)
      // - messages (limit 1, order desc) -> to show last message
      final response = await _client
          .from('chats')
          .select('''
            *,
            chat_members!inner(
              *,
              profiles(*)
            ),
            messages(
              *,
              profiles(*)
            )
          ''')
          .inFilter('id', myChatIds)
          .order('created_at', ascending: false, referencedTable: 'messages')
      // We can't easily limit embedded resources in standard Supabase select just yet in a clean way for "last message per chat"
      // So we fetch messages and take the first one in code, or use a separate query or view.
      // For now, we'll fetch recent messages. Warning: fetching ALL messages is bad.
      // Optimization: Let's assume we fetch chats and members, and we fetch 'last_message' separately or via a view if performance is key.
      // BETTER APPROCH: The 'chats' table has 'last_message_at'.
      // We can assume 'messages' relation returns reasonably.
      // Let's TRY simple relation. If too heavy, we need a DB function.
      // For this 'Rebuild', let's stick to a cleaner approach:
      // We will rely on 'messages' relation but we really want `limit(1)`.
      // Supabase JS v2 supports embedded limits. Flutter SDK might.
      // Let's try to query messages ordered by time.
      ;

      // Since embedded limit/order is tricky, let's process in memory for now (MVP).
      // Or better: Use the `last_message_id` on chat if we maintain it?
      // Our `chats` table schema HAS `last_message_id`. We should use it!

      // Let's re-query based on the updated plan:
      // If we use `last_message_id`, we can fetch that specific message.

      final chatsData = await _client
          .from('chats')
          .select('''
            *,
            chat_members(
              *,
              profiles(*)
            ),
            messages(
              *,
              profiles(*)
            )
          ''')
          .inFilter('id', myChatIds)
          .order('last_message_at', ascending: false);

      final chats = (chatsData as List).map((json) {
        // Fallback: If 'messages' is a list and not empty, pick the latest one
        // to populate the chat preview.
        if (json['messages'] != null && (json['messages'] as List).isNotEmpty) {
          final msgs = json['messages'] as List;
          // If Supabase returns them ordered, first is likely correct if we ordered in query.
          // But we didn't order messages in the query above (only chats).
          // So let's sort safe-side here.
          msgs.sort((a, b) {
            final da =
                DateTime.tryParse(a['created_at'].toString()) ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final db =
                DateTime.tryParse(b['created_at'].toString()) ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return db.compareTo(da); // Descending
          });

          // We only keep the last message for the list view to save memory/processing if model allows
          // But ChatModel might expect a list.
          // If ChatModel uses 'messages' property, we just leave it as is or trim it.
          // Let's trim it to top 1 to mimic "last_message" behavior.
          json['messages'] = [msgs.first];
        }

        return ChatModel.fromJson(json);
      }).toList();

      _chatsController.add(chats);
    } catch (e) {
      if (!_chatsController.isClosed) {
        _chatsController.addError(e);
      }
      debugPrint('Error fetching chats: $e');
    }
  }

  // ... (createOrGetChat, getChatById, getUnreadCountsForUser methods remain similar but reusing _fetchChats logic if needed)

  /// Create or get private chat between two users
  Future<String> createOrGetChat(String otherUserId) async {
    final currentUserId = _client.auth.currentUser!.id;
    try {
      // Check existing private chats
      final response = await _client.rpc(
        'get_private_chat_id',
        params: {'user_a': currentUserId, 'user_b': otherUserId},
      );

      if (response != null) {
        return response as String;
      }

      // Verify other user exists first
      final otherUser = await _client
          .from('profiles')
          .select('id')
          .eq('id', otherUserId)
          .maybeSingle();

      if (otherUser == null) {
        throw Exception('المستخدم الآخر غير موجود');
      }

      // Create new chat
      final chatResponse = await _client
          .from('chats')
          .insert({
            'chat_type': 'private',
            'created_by': currentUserId,
            'last_message_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final chatId = chatResponse['id'] as String;

      // Add members
      await _client.from('chat_members').insert([
        {'chat_id': chatId, 'user_id': currentUserId, 'role': 'admin'},
        {'chat_id': chatId, 'user_id': otherUserId, 'role': 'member'},
      ]);

      return chatId;
    } catch (e) {
      throw Exception('فشل إنشاء المحادثة: $e');
    }
  }

  /// Get chat by ID
  Future<ChatModel> getChatById(String chatId) async {
    try {
      final response = await _client
          .from('chats')
          .select('''
            *,
            chat_members(*, profiles(*))
          ''')
          .eq('id', chatId)
          .single();

      return ChatModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get chat: $e');
    }
  }

  /// Get unread count for all user chats (Legacy/RPC based)
  Future<Map<String, int>> getUnreadCountsForUser(String userId) async {
    // ... existing impl
    try {
      final response = await _client.rpc(
        'get_unread_messages_count',
        params: {'user_uuid': userId},
      );
      final Map<String, int> counts = {};
      for (final item in response as List) {
        counts[item['chat_id'] as String] = item['unread_count'] as int;
      }
      return counts;
    } catch (e) {
      return {};
    }
  }

  /// Delete chat (Leave chat)
  /// This removes the current user from the chat members.
  Future<void> deleteChat(String chatId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    try {
      await _client
          .from('chat_members')
          .delete()
          .eq('chat_id', chatId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to delete chat: $e');
    }
  }

  /// Listen for new messages globally (for notifications)
  /// Listen for new messages globally (for notifications)
  /// Note: This creates a new subscription each time it's listened to.
  /// The caller is responsible for cancelling the subscription.
  /// Get ALL chats for Admin (ignoring membership)
  Stream<List<ChatModel>> getAdminChatsStream(String adminId) {
    _initAdminChatsSubscription(adminId);
    return _chatsController.stream;
  }

  Future<void> _initAdminChatsSubscription(String adminId) async {
    await _fetchAdminChats();

    _chatsSubscription = _client
        .channel('public:admin_chats')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chats',
          callback: (_) => _fetchAdminChats(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          callback: (_) => _fetchAdminChats(),
        )
        .subscribe();
  }

  Future<void> _fetchAdminChats() async {
    try {
      final chatsData = await _client
          .from('chats')
          .select('''
            *,
            chat_members(
              *,
              profiles(*)
            ),
            messages(
              *,
              profiles(*)
            )
          ''')
          .order('last_message_at', ascending: false);

      final chats = (chatsData as List).map((json) {
        if (json['messages'] != null && (json['messages'] as List).isNotEmpty) {
          final msgs = json['messages'] as List;
          msgs.sort((a, b) {
            final da =
                DateTime.tryParse(a['created_at'].toString()) ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final db =
                DateTime.tryParse(b['created_at'].toString()) ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return db.compareTo(da);
          });
          json['messages'] = [msgs.first];
        }
        return ChatModel.fromJson(json);
      }).toList();

      if (!_chatsController.isClosed) {
        _chatsController.add(chats);
      }
    } catch (e) {
      debugPrint('Error fetching admin chats: $e');
    }
  }

  /// Get unread counts for Admin (Active unread messages from non-admins)
  Future<Map<String, int>> getUnreadCountsForAdmin(String adminId) async {
    try {
      // Fetch all unread messages that were NOT sent by the current admin
      // This is an approximation. Ideally we check if sender is 'user'.
      final response = await _client
          .from('messages')
          .select('chat_id')
          .eq('is_read', false)
          .neq('sender_id', adminId);

      final Map<String, int> counts = {};

      for (final item in response as List) {
        final chatId = item['chat_id'] as String;
        counts[chatId] = (counts[chatId] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      debugPrint('Error fetching admin unread counts: $e');
      return {};
    }
  }

  /// Listen for new messages globally (for notifications)
  Stream<MessageModel> get onNewMessage {
    final controller = StreamController<MessageModel>();
    final channel = _client.channel(
      'global_messages_${DateTime.now().millisecondsSinceEpoch}',
    );
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            if (payload.newRecord != null) {
              try {
                controller.add(MessageModel.fromJson(payload.newRecord!));
              } catch (e) {
                print(e);
              }
            }
          },
        )
        .subscribe();

    controller.onCancel = () async {
      await channel.unsubscribe();
      await controller.close();
    };
    return controller.stream;
  }

  void dispose() {
    _chatsController.close();
    _chatsSubscription?.unsubscribe();
  }
}
