import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';

class UploadSnagListScreen extends StatefulWidget {
  final String projectId;
  final String unitId;

  const UploadSnagListScreen({
    super.key,
    required this.projectId,
    required this.unitId,
  });

  @override
  State<UploadSnagListScreen> createState() => _UploadSnagListScreenState();
}

class _UploadSnagListScreenState extends State<UploadSnagListScreen> {
  final List<SnagItem> _snagItems = [];
  final List<File> _uploadedImages = [];
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedCategory = 'جودة التشطيبات';
  //  final ImagePicker _picker = ImagePicker();

  final List<String> _categories = [
    'جودة التشطيبات',
    'الأعمال الصحية',
    'الأعمال الكهربائية',
    'الأبواب والنوافذ',
    'الأرضيات',
    'الدهانات',
    'أخرى',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة العيوب'),
        actions: [
          IconButton(
            icon: const Icon(Icons.checklist),
            onPressed: () {
              _showChecklist();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions
            Container(
              padding: const EdgeInsets.all(Dimensions.spaceL),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.primary.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber,
                    color: AppColors.warning,
                    size: 32,
                  ),
                  const SizedBox(width: Dimensions.spaceL),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'تسجيل العيوب',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'قم بتسجيل جميع العيوب الملاحظة في الوحدة',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Add Snag Form
            Padding(
              padding: const EdgeInsets.all(Dimensions.spaceL),
              child: Container(
                padding: const EdgeInsets.all(Dimensions.spaceL),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(Dimensions.radiusL),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'إضافة عيب جديد',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: Dimensions.spaceL),

                    // Category
                    const Text('التصنيف'),
                    const SizedBox(height: Dimensions.spaceS),
                    DropdownButtonFormField(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        filled: true,
                        border: OutlineInputBorder(),
                      ),
                      items: _categories
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),

                    const SizedBox(height: Dimensions.spaceL),

                    // Location
                    const Text('الموقع'),
                    const SizedBox(height: Dimensions.spaceS),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'مثال: الحمام الرئيسي - الجدار الشمالي',
                        filled: true,
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: Dimensions.spaceL),

                    // Description
                    const Text('وصف العيب'),
                    const SizedBox(height: Dimensions.spaceS),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'صف العيب بالتفصيل...',
                        filled: true,
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: Dimensions.spaceL),

                    // Priority
                    const Text('الأولوية'),
                    const SizedBox(height: Dimensions.spaceS),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('منخفضة'),
                            selected: false,
                            onSelected: (selected) {},
                            selectedColor: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: Dimensions.spaceM),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('متوسطة'),
                            selected: true,
                            onSelected: (selected) {},
                            selectedColor: AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: Dimensions.spaceM),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('عالية'),
                            selected: false,
                            onSelected: (selected) {},
                            selectedColor: AppColors.error,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: Dimensions.spaceL),

                    // Add Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _addSnagItem();
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('إضافة العيب'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Snag Items List
            if (_snagItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(Dimensions.spaceL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'العيوب المسجلة',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_snagItems.length} عيب',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Dimensions.spaceL),
                    ..._snagItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return _buildSnagItem(item, index);
                    }),
                  ],
                ),
              ),

            // Upload Images
            Padding(
              padding: const EdgeInsets.all(Dimensions.spaceL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'إضافة صور',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: Dimensions.spaceL),
                  Text(
                    'أضف صوراً توضيحية للعيوب (اختياري)',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: Dimensions.spaceL),

                  // Image Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: Dimensions.spaceM,
                          mainAxisSpacing: Dimensions.spaceM,
                          childAspectRatio: 1,
                        ),
                    itemCount: _uploadedImages.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _uploadedImages.length) {
                        return GestureDetector(
                          // onTap: _pickImage,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(
                                Dimensions.radiusM,
                              ),
                              border: Border.all(
                                color: AppColors.border,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  color: AppColors.primary,
                                  size: 32,
                                ),
                                SizedBox(height: Dimensions.spaceS),
                                Text(
                                  'إضافة صورة',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      final image = _uploadedImages[index];
                      return Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                Dimensions.radiusM,
                              ),
                              image: DecorationImage(
                                image: FileImage(image),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _uploadedImages.removeAt(index);
                                });
                              },
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // Notes
            Padding(
              padding: const EdgeInsets.all(Dimensions.spaceL),
              child: Container(
                padding: const EdgeInsets.all(Dimensions.spaceL),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Dimensions.radiusL),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3),
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: AppColors.info),
                        SizedBox(width: Dimensions.spaceL),
                        Text(
                          'نصائح للتصوير',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Dimensions.spaceL),
                    Text(
                      '• استخدم إضاءة جيدة\n'
                      '• التقط الصور من زوايا مختلفة\n'
                      '• قم بتضمين مقياس للقياس\n'
                      '• ركز على منطقة العيب\n'
                      '• تجنب الصور المهزوزة',
                      style: TextStyle(color: AppColors.info),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: Dimensions.spaceXL),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(Dimensions.spaceL),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _snagItems.isNotEmpty
              ? () {
                  _submitSnagList();
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusL),
            ),
            disabledBackgroundColor: AppColors.gray300,
          ),
          child: const Text(
            'تقديم قائمة العيوب',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildSnagItem(SnagItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.spaceL),
      padding: const EdgeInsets.all(Dimensions.spaceL),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.description,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () {
                      _editSnagItem(index);
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      size: 18,
                      color: AppColors.error,
                    ),
                    onPressed: () {
                      _deleteSnagItem(index);
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: Dimensions.spaceS),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.spaceM,
                  vertical: Dimensions.spaceXS,
                ),
                decoration: BoxDecoration(
                  color: _getPriorityColor(
                    item.priority,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Dimensions.radiusS),
                ),
                child: Text(
                  item.priority,
                  style: TextStyle(
                    color: _getPriorityColor(item.priority),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: Dimensions.spaceM),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.spaceM,
                  vertical: Dimensions.spaceXS,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(Dimensions.radiusS),
                ),
                child: Text(
                  item.category,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.spaceS),
          Text(
            item.location,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'منخفضة':
        return AppColors.success;
      case 'متوسطة':
        return AppColors.warning;
      case 'عالية':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  void _addSnagItem() {
    if (_descriptionController.text.isEmpty) return;

    final item = SnagItem(
      category: _selectedCategory,
      location: 'الحمام الرئيسي - الجدار الشمالي', // From location field
      description: _descriptionController.text,
      priority: 'متوسطة',
    );

    setState(() {
      _snagItems.add(item);
      _descriptionController.clear();
    });
  }

  void _editSnagItem(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تعديل العيب'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: TextEditingController(
                  text: _snagItems[index].description,
                ),
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'وصف العيب',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                // Update item
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  void _deleteSnagItem(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('حذف العيب'),
          content: const Text('هل تريد حذف هذا العيب؟'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _snagItems.removeAt(index);
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );
  }

  // Future<void> _pickImage() async {
  //   final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
  //   if (pickedFile != null) {
  //     setState(() {
  //       _uploadedImages.add(File(pickedFile.path));
  //     });
  //   }
  // }

  void _showChecklist() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Dimensions.radiusXL),
        ),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(Dimensions.spaceL),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: Dimensions.spaceL),
              const Text(
                'قائمة الفحص',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: Dimensions.spaceL),
              Expanded(
                child: ListView(
                  children: [
                    _buildChecklistItem('الجدران', [
                      'نعومة السطح',
                      'استقامة الجدران',
                      'خلو من التشققات',
                      'جودة الدهان',
                    ]),
                    _buildChecklistItem('الأرضيات', [
                      'استواء الأرضية',
                      'خلو من التشققات',
                      'جودة التبليط',
                      'الفواصل بين البلاط',
                    ]),
                    _buildChecklistItem('الأبواب والنوافذ', [
                      'سهولة الفتح والإغلاق',
                      'خلو من الخدوش',
                      'جودة القفل',
                      'العزل الصوتي',
                    ]),
                    _buildChecklistItem('الأعمال الصحية', [
                      'عدم تسرب المياه',
                      'ضغط الماء',
                      'عملية التصريف',
                      'جودة التركيبات',
                    ]),
                    _buildChecklistItem('الأعمال الكهربائية', [
                      'عملية المفاتيح',
                      'عملية المقابس',
                      'الإضاءة',
                      'لوحة التوزيع',
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: Dimensions.spaceL),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                  child: const Text('تم'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChecklistItem(String title, List<String> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.spaceL),
      padding: const EdgeInsets.all(Dimensions.spaceL),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: Dimensions.spaceL),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: Dimensions.spaceXS),
              child: Row(
                children: [
                  Checkbox(value: false, onChanged: (value) {}),
                  Text(item),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _submitSnagList() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تقديم قائمة العيوب'),
          content: Text('هل تريد تقديم ${_snagItems.length} عيب؟'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showSubmissionSuccess();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('تقديم'),
            ),
          ],
        );
      },
    );
  }

  void _showSubmissionSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.radiusXL),
          ),
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.spaceXL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 48,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: Dimensions.spaceXL),
                const Text(
                  'تم التقديم بنجاح!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: Dimensions.spaceL),
                Text(
                  'تم تسجيل ${_snagItems.length} عيب',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: Dimensions.spaceL),
                if (_uploadedImages.isNotEmpty)
                  Text(
                    'مع ${_uploadedImages.length} صورة',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: Dimensions.spaceXL),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        '/defects-approval',
                        arguments: {
                          'projectId': widget.projectId,
                          'unitId': widget.unitId,
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('التالي: متابعة الإصلاحات'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SnagItem {
  final String category;
  final String location;
  final String description;
  final String priority;

  SnagItem({
    required this.category,
    required this.location,
    required this.description,
    required this.priority,
  });
}
