import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/data/models/message_model.dart';
import 'package:mmm/data/models/user_model.dart';
import 'package:mmm/data/repositories/message_repository.dart';
import 'package:mmm/presentation/cubits/chat/chat_room_cubit.dart';
import 'package:intl/intl.dart' as intl;
import 'package:mmm/routes/route_names.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mmm/presentation/widgets/skeleton_loaders.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ChatRoomScreen extends StatefulWidget {
  final String chatId;
  final String? otherUserId;

  const ChatRoomScreen({super.key, required this.chatId, this.otherUserId});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String _currentUserId =
      Supabase.instance.client.auth.currentUser?.id ?? '';
  final ImagePicker _picker = ImagePicker();

  Map<String, dynamic>? _otherUserProfile;
  bool _isLoadingProfile = false;

  @override
  void initState() {
    super.initState();
    if (widget.otherUserId != null) {
      _loadOtherUserProfile();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadOtherUserProfile() async {
    if (widget.otherUserId == null) return;

    setState(() => _isLoadingProfile = true);

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('*') // Fetch full profile for ClientDetailsScreen
          .eq('id', widget.otherUserId!)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _otherUserProfile = response;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _pickImage(ChatRoomCubit cubit) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null && mounted) {
      cubit.sendImageMessage(File(image.path));
    }
  }

  void _showMessageOptions(
    BuildContext context,
    MessageModel message,
    ChatRoomCubit cubit,
  ) {
    if (message.senderId != _currentUserId) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (message.isText)
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, color: Colors.blue),
              ),
              title: const Text(
                'تعديل الرسالة',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(message, cubit);
              },
            ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete, color: Colors.red),
            ),
            title: const Text(
              'حذف الرسالة',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(message, cubit);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showEditDialog(MessageModel message, ChatRoomCubit cubit) {
    final editController = TextEditingController(text: message.content);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تعديل الرسالة'),
        content: TextField(
          controller: editController,
          autofocus: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              if (editController.text.trim().isNotEmpty) {
                cubit.editMessage(message.id, editController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('حفظ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(MessageModel message, ChatRoomCubit cubit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('حذف الرسالة؟'),
        content: const Text(
          'هل أنت متأكد من رغبتك في حذف هذه الرسالة؟ لا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              cubit.deleteMessage(message.id);
              Navigator.pop(context);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider(
      create: (context) => ChatRoomCubit(
        messageRepository: MessageRepository(),
        chatId: widget.chatId,
      )..loadMessages(),
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F7FA), // Light grey background
            appBar: AppBar(
              automaticallyImplyLeading: false,
              toolbarHeight: 70,
              backgroundColor: Colors.white,
              elevation: 0,
              titleSpacing: 0,
              title: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_rounded,
                      color: Colors.black87,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  if (_isLoadingProfile)
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    GestureDetector(
                      onTap: () {
                        if (_otherUserProfile != null) {
                          try {
                            final user = UserModel.fromJson(_otherUserProfile!);
                            Navigator.pushNamed(
                              context,
                              '${RouteNames.manageClients}/client-details',
                              arguments: user,
                            );
                          } catch (e) {
                            debugPrint('Error navigating to profile: $e');
                          }
                        }
                      },
                      child: Skeletonizer(
                        enabled: _isLoadingProfile,
                        child: Row(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                      width: 2,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 22,
                                    backgroundColor: AppColors.primary
                                        .withOpacity(0.1),
                                    backgroundImage:
                                        _otherUserProfile != null &&
                                            _otherUserProfile!['avatar_url'] !=
                                                null
                                        ? NetworkImage(
                                            _otherUserProfile!['avatar_url'],
                                          )
                                        : null,
                                    child:
                                        _otherUserProfile?.containsKey(
                                                  'avatar_url',
                                                ) ==
                                                false ||
                                            _otherUserProfile?['avatar_url'] ==
                                                null
                                        ? Text(
                                            (_otherUserProfile?['full_name'] ??
                                                    'U')
                                                .substring(0, 1)
                                                .toUpperCase(),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                              fontSize: 18,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                                if (!_isLoadingProfile) // Hide online status when loading
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _otherUserProfile?['full_name'] ??
                                      'اسم المستخدم',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (_otherUserProfile?['phone'] != null ||
                                    _isLoadingProfile)
                                  Text(
                                    _otherUserProfile?['phone'] ?? '0500000000',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(color: Colors.grey[200], height: 1),
              ),
            ),
            body: Column(
              children: [
                // Messages List
                Expanded(
                  child: BlocConsumer<ChatRoomCubit, ChatRoomState>(
                    listener: (context, state) {
                      if (state is ChatRoomLoaded) {
                        // Trigger scroll to bottom on new messages
                        // Wait slightly for list to render
                        Future.delayed(const Duration(milliseconds: 100), () {
                          // _scrollToBottom(); // Auto-scroll logic if needed
                        });
                      }
                      if (state is ChatRoomError) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(state.message)));
                      }
                    },
                    builder: (context, state) {
                      if (state is ChatRoomLoading) {
                        return const ChatMessagesSkeleton(itemCount: 12);
                      }

                      if (state is ChatRoomLoaded) {
                        if (state.messages.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.chat_bubble_outline,
                                    size: 48,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'لا توجد رسائل بعد',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'ابدأ المحادثة الآن وأرسل التحية!',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          reverse:
                              true, // Standard chat behavior: bottom to top
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 20,
                          ),
                          itemCount: state.messages.length,
                          itemBuilder: (context, index) {
                            // Reverse index access since list is reversed
                            final messageIndex =
                                state.messages.length - 1 - index;
                            final message = state.messages[messageIndex];

                            final isMe = message.senderId == _currentUserId;

                            // Check if previous message (visually above) has same date
                            // Since list is reversed in UI but normal in state:
                            // "Previous" visually is index - 1 in state list
                            final showDate =
                                messageIndex == 0 ||
                                state
                                        .messages[messageIndex - 1]
                                        .createdAt
                                        .day !=
                                    message.createdAt.day;

                            return Column(
                              children: [
                                if (showDate)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 20,
                                    ),
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          intl.DateFormat(
                                            'd MMMM yyyy',
                                            'ar',
                                          ).format(message.createdAt),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                Align(
                                  alignment: isMe
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: GestureDetector(
                                    onLongPress: () => _showMessageOptions(
                                      context,
                                      message,
                                      context.read<ChatRoomCubit>(),
                                    ),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                            0.75,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isMe
                                            ? AppColors.primary
                                            : Colors.white,
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(20),
                                          topRight: const Radius.circular(20),
                                          bottomLeft: isMe
                                              ? const Radius.circular(20)
                                              : const Radius.circular(4),
                                          bottomRight: isMe
                                              ? const Radius.circular(4)
                                              : const Radius.circular(20),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.03,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Image Content
                                            if (message.isImage)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 8,
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  child: Stack(
                                                    children: [
                                                      Image.network(
                                                        message.mediaUrl!,
                                                        fit: BoxFit.cover,
                                                        width: double.infinity,
                                                        loadingBuilder:
                                                            (
                                                              context,
                                                              child,
                                                              loadingProgress,
                                                            ) {
                                                              if (loadingProgress ==
                                                                  null)
                                                                return child;
                                                              return Container(
                                                                height: 200,
                                                                width: double
                                                                    .infinity,
                                                                color: Colors
                                                                    .grey[100],
                                                                child: Center(
                                                                  child: CircularProgressIndicator(
                                                                    value:
                                                                        loadingProgress.expectedTotalBytes !=
                                                                            null
                                                                        ? loadingProgress.cumulativeBytesLoaded /
                                                                              loadingProgress.expectedTotalBytes!
                                                                        : null,
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                        errorBuilder:
                                                            (
                                                              ctx,
                                                              err,
                                                              _,
                                                            ) => Container(
                                                              height: 150,
                                                              color: Colors
                                                                  .grey[200],
                                                              child: const Center(
                                                                child: Icon(
                                                                  Icons
                                                                      .broken_image,
                                                                  color: Colors
                                                                      .grey,
                                                                ),
                                                              ),
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),

                                            // Text Content
                                            if (message.content != null &&
                                                message.content!.isNotEmpty)
                                              Text(
                                                message.content!,
                                                style: TextStyle(
                                                  color: isMe
                                                      ? Colors.white
                                                      : Colors.black87,
                                                  fontSize: 16,
                                                  height: 1.4,
                                                ),
                                              ),

                                            const SizedBox(height: 4),

                                            // Metadata (Time & Read Status)
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment: isMe
                                                  ? MainAxisAlignment.end
                                                  : MainAxisAlignment.start,
                                              children: [
                                                if (message.isEdited)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          left: 4,
                                                        ),
                                                    child: Text(
                                                      'معدلة',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: isMe
                                                            ? Colors.white70
                                                            : Colors.grey[500],
                                                        fontStyle:
                                                            FontStyle.italic,
                                                      ),
                                                    ),
                                                  ),
                                                Text(
                                                  intl.DateFormat(
                                                    'h:mm a',
                                                  ).format(message.createdAt),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: isMe
                                                        ? Colors.white70
                                                        : Colors.grey[500],
                                                  ),
                                                ),
                                                if (isMe) ...[
                                                  const SizedBox(width: 4),
                                                  Icon(
                                                    message.isRead
                                                        ? Icons.done_all
                                                        : Icons.done,
                                                    size: 14,
                                                    color: message.isRead
                                                        ? Colors
                                                              .white // or a distinct read color if bg is light
                                                        : Colors.white70,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      }

                      return const SizedBox();
                    },
                  ),
                ),

                // Message Composer Area
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        offset: const Offset(0, -4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(Icons.add, color: AppColors.primary),
                            onPressed: () {
                              final cubit = context.read<ChatRoomCubit>();
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                builder: (cntx) => Container(
                                  margin: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Wrap(
                                    children: [
                                      ListTile(
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.purple.withOpacity(
                                              0.1,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.image,
                                            color: Colors.purple,
                                          ),
                                        ),
                                        title: const Text('معرض الصور'),
                                        onTap: () {
                                          Navigator.pop(cntx);
                                          _pickImage(cubit);
                                        },
                                      ),
                                      ListTile(
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(
                                              0.1,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt,
                                            color: Colors.orange,
                                          ),
                                        ),
                                        title: const Text('الكايمرا'),
                                        onTap: () {
                                          Navigator.pop(cntx);
                                          // TODO: Implement camera logic
                                        },
                                      ),
                                      ListTile(
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.insert_drive_file,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        title: const Text('مستند'),
                                        onTap: () {
                                          Navigator.pop(cntx);
                                          // TODO: Implement file picker
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.grey),
                            ),
                            child: TextField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                hintText: 'اكتب رسالتك...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                isDense: true,
                              ),
                              minLines: 1,
                              maxLines: 4,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        BlocBuilder<ChatRoomCubit, ChatRoomState>(
                          builder: (context, state) {
                            bool isSending = false;
                            if (state is ChatRoomLoaded) {
                              isSending = state.isSending;
                            }
                            return Container(
                              margin: const EdgeInsets.only(bottom: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: isSending
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.send_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                onPressed: isSending
                                    ? null
                                    : () {
                                        final content = _messageController.text;
                                        if (content.trim().isNotEmpty) {
                                          context
                                              .read<ChatRoomCubit>()
                                              .sendTextMessage(content);
                                          _messageController.clear();
                                          // _scrollToBottom will be handled by list update
                                        }
                                      },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
