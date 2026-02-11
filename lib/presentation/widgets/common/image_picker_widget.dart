import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'dart:io';

class ImagePickerWidget extends StatefulWidget {
  final Function(String) onImageSelected;
  final String? initialImageUrl;
  final double height;
  final double width;
  final bool allowCamera;
  final bool allowGallery;
  final String emptyText;

  const ImagePickerWidget({
    super.key,
    required this.onImageSelected,
    this.initialImageUrl,
    this.height = 200,
    this.width = double.infinity,
    this.allowCamera = true,
    this.allowGallery = true,
    this.emptyText = 'اضغط لاختيار صورة',
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final ImagePicker _picker = ImagePicker();
  String? _selectedImagePath;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _showImageSourceDialog,
      child: Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(Dimensions.radiusL),
          border: Border.all(color: AppColors.border),
          image: _getImageDecoration(),
        ),
        child: _selectedImagePath == null && widget.initialImageUrl == null
            ? _buildEmptyState()
            : _buildImageOverlay(),
      ),
    );
  }

  DecorationImage? _getImageDecoration() {
    if (_selectedImagePath != null) {
      return DecorationImage(
        image: FileImage(File(_selectedImagePath!)),
        fit: BoxFit.cover,
      );
    } else if (widget.initialImageUrl != null) {
      return DecorationImage(
        image: NetworkImage(widget.initialImageUrl!),
        fit: BoxFit.cover,
      );
    }
    return null;
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.add_photo_alternate_outlined,
          size: 48,
          color: AppColors.textSecondary,
        ),
        const SizedBox(height: Dimensions.spaceS),
        Text(
          widget.emptyText,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildImageOverlay() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.3),
          ],
        ),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.spaceM),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _showImageSourceDialog,
                icon: const Icon(Icons.edit, color: Colors.white),
                tooltip: 'تغيير الصورة',
              ),
              if (_selectedImagePath != null || widget.initialImageUrl != null)
                IconButton(
                  onPressed: _removeImage,
                  icon: const Icon(Icons.delete, color: Colors.white),
                  tooltip: 'حذف الصورة',
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            if (widget.allowCamera)
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('التقاط صورة'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            if (widget.allowGallery)
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('اختيار من المعرض'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ListTile(
              leading: const Icon(Icons.close, color: AppColors.error),
              title: const Text('إلغاء'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
        });
        widget.onImageSelected(image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل اختيار الصورة: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImagePath = null;
    });
    widget.onImageSelected('');
  }
}
