import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/data/models/message_model.dart';
import 'package:mmm/data/repositories/chat_repository.dart';
import 'package:mmm/routes/route_names.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/presentation/cubits/profile/profile_cubit.dart';
import 'package:mmm/core/utils/global_route_observer.dart';

class GlobalMessageListener extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const GlobalMessageListener({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  @override
  State<GlobalMessageListener> createState() => _GlobalMessageListenerState();
}

class _GlobalMessageListenerState extends State<GlobalMessageListener> {
  StreamSubscription? _subscription;
  RealtimeChannel? _bookingChannel;

  @override
  void initState() {
    super.initState();
    _subscribeToMessages();
    _subscribeToBookings();
  }

  void _subscribeToMessages() {
    final chatRepo = context.read<ChatRepository>();
    _subscription = chatRepo.onNewMessage.listen((message) {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      
      // 1. Check if message is from self
      if (currentUserId != null && message.senderId == currentUserId) {
        return;
      }

      // 2. Check if user is currently in the specific chat room
      final isChatRoom = GlobalRouteObserver.currentRouteName == RouteNames.chatRoom;
      final args = GlobalRouteObserver.currentRouteArgs;
      
      if (isChatRoom && args is Map) {
        final currentChatId = args['chatId'];
        // If current chat ID matches the message's chat ID, don't show notification
        if (currentChatId == message.chatId) {
          return;
        }
      }

      // 3. Show Top Notification
      _showNotification(message);
    });
  }

  void _subscribeToBookings() {
    // ... existing booking logic ...
     print('🔔 تهيئة مستمع الحجوزات...');
    
    // Subscribe to INSERT on public.subscriptions
    _bookingChannel = Supabase.instance.client
        .channel('public:subscriptions')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'subscriptions',
          callback: (payload) {
            _handleNewBooking(payload.newRecord);
          },
        )
        .subscribe();
  }

  Future<void> _handleNewBooking(Map<String, dynamic> record) async {
    // ... existing booking handler ...
    print('🔔 حجز جديد تم اكتشافه: ${record['id']}');

    if (!mounted) return;

    final profileCubit = context.read<ProfileCubit>();
    if (profileCubit.state is ProfileLoaded) {
      final user = (profileCubit.state as ProfileLoaded).user;
      if (user.role != 'admin' && user.role != 'super_admin') {
        print('👤 المستخدم ليس مسؤولاً، تجاهل الإشعار.');
        return;
      }
    } else {
      return;
    }

    try {
      final userId = record['user_id'];
      final projectId = record['project_id'];
      final unitId = record['unit_id'];

      final clientRes = await Supabase.instance.client
          .from('profiles')
          .select('full_name, phone')
          .eq('id', userId)
          .single();
      
      final projectRes = await Supabase.instance.client
          .from('projects')
          .select('name_ar')
          .eq('id', projectId)
          .single();

      String unitNumber = 'غير محدد';
       if (unitId != null) {
        final unitRes = await Supabase.instance.client
            .from('units')
            .select('unit_number')
            .eq('id', unitId)
            .maybeSingle(); 
        if (unitRes != null) {
            unitNumber = unitRes['unit_number'].toString();
        }
      }

      if (mounted) {
        _showBookingPopup(
          clientName: clientRes['full_name'] ?? 'عميل جديد',
          projectName: projectRes['name_ar'] ?? 'المشروع',
          unitNumber: unitNumber,
          bookingId: record['id'],
          createdAt: record['created_at'],
        );
      }
    } catch (e) {
      print('❌ خطأ في معالجة إشعار الحجز: $e');
    }
  }

  void _showBookingPopup({
    required String clientName,
    required String projectName,
    required String unitNumber,
    required String bookingId,
    required String createdAt,
  }) {
     late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 60, 
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: -100, end: 0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, value),
                child: child,
              );
            },
            child: Dismissible(
              key: ValueKey(bookingId),
              direction: DismissDirection.up,
              onDismissed: (_) {
                overlayEntry.remove();
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                ),
                child: InkWell(
                  onTap: () {
                    overlayEntry.remove();
                    widget.navigatorKey.currentState?.pushNamed(
                         RouteNames.adminDashboard, 
                         arguments: {'tab': 9}, 
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.bookmark_added_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'حجز جديد! 🎉',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(
                                  _formatTime(createdAt),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$clientName قام بحجز وحدة $unitNumber',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'في مشروع $projectName',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    widget.navigatorKey.currentState?.overlay?.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 6), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  String _formatTime(String isoString) {
    try {
      final date = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      if (now.difference(date).inMinutes < 1) {
        return 'الآن';
      }
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  void _showNotification(MessageModel message) {
    String previewText = message.content.toString();
    if (message.type == MessageType.image) {
      previewText = '📷 صورة';
    } else if (message.type == MessageType.file) {
      previewText = '📁 ملف';
    } else if (message.type == MessageType.video) {
        previewText = '🎥 فيديو';
    } else if (message.type == MessageType.location) {
        previewText = '📍 موقع';
    }

    // Sender Info
    final senderName = message.sender?.fullName ?? 'رسالة جديدة';
    final senderAvatar = message.sender?.avatarUrl;

    // Show custom Top Notification using Overlay
    late OverlayEntry overlayEntry;
    final uniqueKey = UniqueKey();

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: -200, end: 0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, value),
                child: child,
              );
            },
            child: Dismissible(
              key: uniqueKey,
              direction: DismissDirection.up,
              onDismissed: (_) {
                if (overlayEntry.mounted) overlayEntry.remove();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.6),
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: InkWell(
                         onTap: () {
                            if (overlayEntry.mounted) overlayEntry.remove();
                            widget.navigatorKey.currentState?.pushNamed(
                              RouteNames.chatRoom,
                              arguments: {
                                'chatId': message.chatId,
                                'otherUserId': message.senderId,
                              },
                            );
                          },
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
                              ),
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                backgroundImage: senderAvatar != null 
                                    ? NetworkImage(senderAvatar) 
                                    : null,
                                child: senderAvatar == null
                                    ? Text(
                                        senderName[0].toUpperCase(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // Content
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          senderName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Text(
                                          'الآن',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    previewText,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppColors.textSecondary.withOpacity(0.8),
                                      fontSize: 13,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.navigatorKey.currentState?.overlay != null) {
      widget.navigatorKey.currentState?.overlay?.insert(overlayEntry);
      
      Future.delayed(const Duration(seconds: 5), () {
        if (overlayEntry.mounted) {
          overlayEntry.remove();
        }
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _bookingChannel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
