import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/document_model.dart';
import 'package:intl/intl.dart';

class DocumentCard extends StatelessWidget {
  final DocumentModel document;
  final VoidCallback? onTap;
  final VoidCallback? onDownload;
  final VoidCallback? onShare;

  const DocumentCard({
    super.key,
    required this.document,
    this.onTap,
    this.onDownload,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('dd MMMM yyyy', 'ar');

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(Dimensions.cardRadius),
      elevation: 2,
      shadowColor: AppColors.shadow,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.spaceL),
          child: Row(
            children: [
              // Document Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _getTypeColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Dimensions.radiusM),
                ),
                child: Center(
                  child: Icon(
                    document.isPdf ? Icons.picture_as_pdf : Icons.image,
                    color: _getTypeColor(),
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: Dimensions.spaceM),

              // Document Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      document.displayTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Dimensions.spaceXS),

                    // Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.spaceM,
                        vertical: Dimensions.spaceXS,
                      ),
                      decoration: BoxDecoration(
                        color: _getTypeColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(Dimensions.radiusS),
                      ),
                      child: Text(
                        document.type.displayName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getTypeColor(),
                        ),
                      ),
                    ),
                    const SizedBox(height: Dimensions.spaceS),

                    // Date & Size
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: Dimensions.spaceXS),
                        Text(
                          dateFormatter.format(document.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textHint,
                              ),
                        ),
                        if (document.fileSize > 0) ...[
                          const SizedBox(width: Dimensions.spaceM),
                          Text(
                            '• ${_formatFileSize(document.fileSize)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textHint,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Action Buttons
              Column(
                children: [
                  if (onDownload != null)
                    IconButton(
                      onPressed: onDownload,
                      icon: const Icon(Icons.download_outlined),
                      color: AppColors.primary,
                      iconSize: 22,
                    ),
                  if (onShare != null)
                    IconButton(
                      onPressed: onShare,
                      icon: const Icon(Icons.share_outlined),
                      color: AppColors.gray500,
                      iconSize: 20,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor() {
    switch (document.type) {
      case DocumentType.contract:
        return AppColors.primary;
      case DocumentType.invoice:
        return AppColors.warning;
      case DocumentType.receipt:
        return AppColors.success;
      case DocumentType.report:
        return AppColors.info;
      case DocumentType.certificate:
        return AppColors.accent;
      default:
        return AppColors.gray500;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
