import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/data/models/chat_model.dart';
import 'package:mmm/data/models/user_model.dart';
import 'package:mmm/presentation/cubits/chat/chat_list_cubit.dart';
import 'package:mmm/presentation/screens/chat/users_list_screen.dart';
import 'package:mmm/routes/route_names.dart';
import 'package:intl/intl.dart' as intl;
import 'package:mmm/presentation/widgets/skeleton_loaders.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Force reload chats to ensure unread counts are up-to-date
    context.read<ChatListCubit>().loadChats();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'بحث في المحادثات...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                context.read<ChatListCubit>().searchChats(value);
              },
            ),
          ),

          // Divider
          const Divider(height: 1),

          // Chat List
          Expanded(
            child: BlocBuilder<ChatListCubit, ChatListState>(
              builder: (context, state) {
                if (state is ChatListLoading && state is! ChatListLoaded) {
                  return const ChatListSkeleton();
                }

                if (state is ChatListError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(state.message),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<ChatListCubit>().loadChats();
                          },
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is ChatListLoaded) {
                  final chats = state.filteredChats;
                  final unreadCounts = state.unreadCounts;

                  if (chats.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isEmpty
                                ? 'لا توجد محادثات بعد'
                                : 'لا توجد نتائج للبحث',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (_searchController.text.isEmpty) ...[
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const UsersListScreen(),
                                  ),
                                ).then((_) {
                                  if (context.mounted) {
                                    context.read<ChatListCubit>().loadChats();
                                  }
                                });
                              },
                              icon: const Icon(Icons.add_comment_rounded),
                              label: const Text('بدء محادثة جديدة'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: chats.length + 1, // +1 for "Start New Chat" tile
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const UsersListScreen(),
                              ),
                            ).then((_) {
                              if (context.mounted) {
                                context.read<ChatListCubit>().loadChats();
                              }
                            });
                          },
                          leading: CircleAvatar(
                            backgroundColor:
                                AppColors.primary.withOpacity(0.1),
                            child: const Icon(
                              Icons.person_add,
                              color: AppColors.primary,
                            ),
                          ),
                          title: const Text(
                            'بدء محادثة جديدة',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          subtitle: const Text('تواصل مع الإدارة والدعم'),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        );
                      }

                      final chat = chats[index - 1];
                      final unreadCount = unreadCounts[chat.id] ?? 0;

                      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
                      final otherMember = chat.members.firstWhere(
                        (m) => m.id != currentUserId,
                        orElse: () => chat.members.isNotEmpty
                            ? chat.members.first
                            : UserModel(
                                id: '',
                                email: '',
                                fullName: 'Unknown',
                                role: 'user',
                                createdAt: DateTime.now(),
                                updatedAt: DateTime.now(),
                              ),
                      );

                      final isPrivate = chat.type == ChatType.private;
                      final displayTitle = isPrivate 
                          ? (otherMember.fullName ?? 'مستخدم')
                          : (chat.title ?? 'محادثة');
                      final displayAvatar = isPrivate 
                          ? otherMember.avatarUrl 
                          : chat.avatarUrl;
                      
                      String lastMessagePreview = 'اضغط للعرض...';
                      if (chat.lastMessage != null) {
                        if (chat.lastMessage!.isImage) {
                          lastMessagePreview = '📷 صورة';
                        } else if (chat.lastMessage!.isFile) {
                          lastMessagePreview = '📎 ملف';
                        } else if (chat.lastMessage!.isVideo) {
                          lastMessagePreview = '🎥 فيديو';
                        } else if (chat.lastMessage!.isLocation) {
                          lastMessagePreview = '📍 موقع';
                        } else {
                          lastMessagePreview = chat.lastMessage!.content ?? '';
                        }
                      }

                      return ListTile(
                        onLongPress: () {
                          final chatListCubit = context.read<ChatListCubit>();
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('حذف المحادثة'),
                              content: const Text(
                                'هل أنت متأكد من رغبتك في حذف هذه المحادثة؟',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('إلغاء'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () {
                                    chatListCubit.deleteChat(chat.id);
                                    Navigator.pop(context);
                                  },
                                  child: const Text('حذف'),
                                ),
                              ],
                            ),
                          );
                        },
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            RouteNames.chatRoom,
                            arguments: {
                              'chatId': chat.id,
                              'otherUserId': otherMember.id,
                            },
                          ).then((_) {
                            // Refresh list when returning from chat room to update order/last message
                            if (context.mounted) {
                              // Optimistically clear unread count
                              context.read<ChatListCubit>().markChatAsRead(chat.id);
                              context.read<ChatListCubit>().loadChats();
                            }
                          });
                        },
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: AppColors.primary.withOpacity(
                                0.1,
                              ),
                              backgroundImage: displayAvatar != null
                                  ? NetworkImage(displayAvatar)
                                  : null,
                              child: displayAvatar == null
                                  ? Text(
                                      (displayTitle)
                                          .substring(0, 1)
                                          .toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    )
                                  : null,
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    unreadCount > 99 ? '99+' : '$unreadCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Text(
                          displayTitle,
                          style: TextStyle(
                            fontWeight: unreadCount > 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Row(
                          children: [
                            Expanded(
                              child: Text(
                                lastMessagePreview,
                                style: TextStyle(
                                  color: unreadCount > 0
                                      ? Colors.black87
                                      : Colors.grey[600],
                                  fontWeight: unreadCount > 0
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                             if (chat.lastMessageAt != null)
                              Text(
                                _formatDate(chat.lastMessageAt!),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: unreadCount > 0
                                      ? AppColors.primary
                                      : Colors.grey[500],
                                  fontWeight: unreadCount > 0
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }

                return const SizedBox();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UsersListScreen()),
          ).then((_) {
            if (context.mounted) {
              context.read<ChatListCubit>().loadChats();
            }
          });
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_comment_rounded),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return intl.DateFormat('h:mm a').format(date);
    } else if (difference.inDays < 7) {
      return intl.DateFormat('EEEE').format(date); // Day name
    } else {
      return intl.DateFormat('yyyy/MM/dd').format(date);
    }
  }
}
