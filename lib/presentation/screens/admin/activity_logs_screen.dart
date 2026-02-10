// lib/presentation/screens/admin/activity_logs_screen.dart
import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/activity_log_model.dart';
import 'package:mmm/data/repositories/admin_repository.dart';
import 'package:intl/intl.dart';

class ActivityLogsScreen extends StatefulWidget {
  const ActivityLogsScreen({super.key});

  @override
  State<ActivityLogsScreen> createState() => _ActivityLogsScreenState();
}

class _ActivityLogsScreenState extends State<ActivityLogsScreen> {
  final _repository = AdminRepository();
  List<ActivityLogModel> _logs = [];
  bool _isLoading = true;
  String? _filterAction;
  String? _filterEntityType;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      final logs = await _repository.getActivityLogs(action: _filterAction);
      setState(() {
        _logs = logs as List<ActivityLogModel>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في تحميل السجلات: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('سجل النشاطات'),
        backgroundColor: AppColors.primary,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                if (value.startsWith('action:')) {
                  _filterAction = value.replaceFirst('action:', '');
                } else if (value.startsWith('entity:')) {
                  _filterEntityType = value.replaceFirst('entity:', '');
                } else if (value == 'clear') {
                  _filterAction = null;
                  _filterEntityType = null;
                }
              });
              _loadLogs();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'clear', child: Text('إزالة الفلاتر')),
              const PopupMenuItem(value: 'action:create', child: Text('إنشاء')),
              const PopupMenuItem(value: 'action:update', child: Text('تحديث')),
              const PopupMenuItem(value: 'action:delete', child: Text('حذف')),
              const PopupMenuItem(
                value: 'entity:project',
                child: Text('مشاريع'),
              ),
              const PopupMenuItem(
                value: 'entity:user',
                child: Text('مستخدمون'),
              ),
              const PopupMenuItem(
                value: 'entity:subscription',
                child: Text('اشتراكات'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
          ? const Center(child: Text('لا توجد سجلات'))
          : RefreshIndicator(
              onRefresh: _loadLogs,
              child: ListView.builder(
                padding: const EdgeInsets.all(Dimensions.spaceL),
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  return _buildLogCard(log);
                },
              ),
            ),
    );
  }

  Widget _buildLogCard(ActivityLogModel log) {
    final actionColor = _getActionColor(log.action);

    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.spaceM),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.spaceM,
                    vertical: Dimensions.spaceS,
                  ),
                  decoration: BoxDecoration(
                    color: actionColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(Dimensions.radiusS),
                  ),
                  child: Text(
                    _getActionDisplayName(log.action),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: actionColor,
                    ),
                  ),
                ),
                const SizedBox(width: Dimensions.spaceM),
                if (log.entityType != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.spaceM,
                      vertical: Dimensions.spaceS,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(Dimensions.radiusS),
                    ),
                    child: Text(
                      _getEntityDisplayName(log.entityType!),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                const Spacer(),
                Text(
                  DateFormat('HH:mm').format(log.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Dimensions.spaceM),
            if (log.description != null)
              Text(log.description!, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: Dimensions.spaceS),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: Dimensions.spaceS),
                Text(
                  DateFormat('yyyy-MM-dd').format(log.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (log.ipAddress != null) ...[
                  const SizedBox(width: Dimensions.spaceL),
                  Icon(
                    Icons.computer,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: Dimensions.spaceS),
                  Text(
                    log.ipAddress!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getActionColor(String action) {
    switch (action.toLowerCase()) {
      case 'create':
        return AppColors.success;
      case 'update':
        return AppColors.primary;
      case 'delete':
        return AppColors.error;
      case 'login':
        return Colors.purple;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getActionDisplayName(String action) {
    switch (action.toLowerCase()) {
      case 'create':
        return 'إنشاء';
      case 'update':
        return 'تحديث';
      case 'delete':
        return 'حذف';
      case 'login':
        return 'تسجيل دخول';
      case 'logout':
        return 'تسجيل خروج';
      default:
        return action;
    }
  }

  String _getEntityDisplayName(String entity) {
    switch (entity.toLowerCase()) {
      case 'project':
        return 'مشروع';
      case 'user':
        return 'مستخدم';
      case 'subscription':
        return 'اشتراك';
      case 'installment':
        return 'قسط';
      case 'handover':
        return 'تسليم';
      case 'document':
        return 'مستند';
      default:
        return entity;
    }
  }
}
