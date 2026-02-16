import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/data/models/message_model.dart';
import 'package:mmm/data/repositories/chat_repository.dart';
import 'package:mmm/routes/route_names.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/presentation/cubits/profile/profile_cubit.dart';

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
      // Only show notification if message is NOT from current user
      if (currentUserId != null && message.senderId != currentUserId) {
        _showNotification(message);
      }
    });
  }

  void _subscribeToBookings() {
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

    Overlay.of(context).insert(overlayEntry);

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
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.chat_bubble, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'رسالة جديدة',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    previewText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'عرض',
          textColor: Colors.white,
          onPressed: () {
            widget.navigatorKey.currentState?.pushNamed(
              RouteNames.chatRoom,
              arguments: {
                'chatId': message.chatId,
                'otherUserId': message.senderId,
              },
            );
          },
        ),
      ),
    );
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
