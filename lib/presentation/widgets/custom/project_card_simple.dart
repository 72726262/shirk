import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/project_model.dart';
import 'package:intl/intl.dart';

/// Alternative ProjectCard that can work with individual parameters
/// for screens that don't have a full ProjectModel available
class ProjectCardSimple extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String location;
  final double progress;
  final String status;
  final String price;
  final int availableUnits;
  final VoidCallback? onTap;

  const ProjectCardSimple({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.location,
    required this.progress,
    required this.status,
    required this.price,
    required this.availableUnits,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(Dimensions.cardRadius),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(Dimensions.cardRadius),
                  ),
                  child: AspectRatio(
                    aspectRatio: Dimensions.aspectRatioProject,
                    child: _buildProjectImage(),
                  ),
                ),
                // Status Badge
                Positioned(
                  top: Dimensions.spaceM,
                  right: Dimensions.spaceM,
                  child: _buildStatusBadge(),
                ),
              ],
            ),

            // Project Info
            Padding(
              padding: const EdgeInsets.all(Dimensions.spaceL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Dimensions.spaceS),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: Dimensions.spaceXS),
                      Expanded(
                        child: Text(
                          location,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.spaceM),

                  // Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'نسبة الإنجاز',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${progress.toInt()}%',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Dimensions.spaceXS),
                      LinearProgressIndicator(
                        value: progress / 100,
                        backgroundColor: AppColors.gray200,
                        color: AppColors.primary,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.spaceM),

                  // Price and Units
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'السعر من',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            _formatPrice(price),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.spaceM,
                          vertical: Dimensions.spaceXS,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusM,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.apartment,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: Dimensions.spaceXS),
                            Text(
                              '$availableUnits وحدة متاحة',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================ التحقق من صحة رابط الصورة (مطور) ================
  bool _isValidImageUrl(String url) {
    if (url.isEmpty) return false;
    if (url.trim().isEmpty) return false;
    if (url == 'file://' || url == 'file:///') return false;
    if (url.startsWith('file://')) return false;
    if (!url.startsWith('http://') && !url.startsWith('https://')) return false;

    // لو الرابط من Supabase ومش فيه query parameters
    if (url.contains('supabase.co/storage') && !url.contains('?')) {
      return false; // اعرض placeholder لأن محتاج query parameter
    }

    return true;
  }

  // ================ الصورة مع Fallback احترافي ================
  Widget _buildProjectImage() {
    // لو مش رابط صحيح - اعرض التصميم الاحترافي فوراً
    if (!_isValidImageUrl(imageUrl)) {
      return _buildElegantPlaceholder();
    }

    // هنا بس نستخدم Image.network
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('⚠️ فشل تحميل الصورة: $error');
        return _buildErrorPlaceholder();
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: AppColors.gray100,
          child: Center(
            child: SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            ),
          ),
        );
      },
    );
  }

  // ================ Placeholder أنيق (حالة مفيش صورة خالص) ================
  Widget _buildElegantPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gray50, AppColors.gray100],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.business_center_rounded,
                size: 42,
                color: AppColors.primary.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================ Placeholder عند فشل التحميل ================
  Widget _buildErrorPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gray100, AppColors.gray200],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                size: 36,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'تعذر تحميل الصورة',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================ Status Badge ================
  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.spaceM,
        vertical: Dimensions.spaceXS,
      ),
      decoration: BoxDecoration(
        color: _getStatusColor().withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor().withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ================ Price Formatter ================
  String _formatPrice(String price) {
    if (price.isEmpty || price == '0' || price == 'يحدد لاحقاً') {
      return 'يحدد لاحقاً';
    }

    try {
      final number = num.tryParse(price.replaceAll(RegExp(r'[^0-9]'), ''));
      if (number != null && number > 0) {
        final formatter = NumberFormat('#,###', 'ar');
        return '${formatter.format(number)} ج.م';
      }
    } catch (e) {
      // لو فشل التنسيق، استخدم القيمة الأصلية
    }
    return price;
  }

  Color _getStatusColor() {
    switch (status) {
      case 'قيد التنفيذ':
        return AppColors.info;
      case 'مكتمل':
        return AppColors.success;
      case 'قيد الإعداد':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }
}
