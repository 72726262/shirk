import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';

class DocumentsHubScreen extends StatefulWidget {
  const DocumentsHubScreen({super.key});

  @override
  State<DocumentsHubScreen> createState() => _DocumentsHubScreenState();
}

class _DocumentsHubScreenState extends State<DocumentsHubScreen> {
  String _selectedFilter = 'all';
  String _searchQuery = '';
  List<String> _selectedDocuments = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مركز المستندات'),
        actions: [
          if (_selectedDocuments.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                _deleteSelectedDocuments();
              },
            ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () {
              _uploadDocument();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(Dimensions.spaceL),
            color: AppColors.surface,
            child: Column(
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(Dimensions.radiusL),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'ابحث في المستندات...',
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: Dimensions.spaceL,
                        vertical: Dimensions.spaceM,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: Dimensions.spaceL),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('الكل', 'all'),
                      const SizedBox(width: Dimensions.spaceS),
                      _buildFilterChip('العقود', 'contracts'),
                      const SizedBox(width: Dimensions.spaceS),
                      _buildFilterChip('الفواتير', 'invoices'),
                      const SizedBox(width: Dimensions.spaceS),
                      _buildFilterChip('التقارير', 'reports'),
                      const SizedBox(width: Dimensions.spaceS),
                      _buildFilterChip('الشهادات', 'certificates'),
                      const SizedBox(width: Dimensions.spaceS),
                      _buildFilterChip('غير موقعة', 'unsigned'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Storage Info
          Container(
            padding: const EdgeInsets.all(Dimensions.spaceL),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.primary.withOpacity(0.05),
                ],
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.storage, color: AppColors.primary, size: 32),
                const SizedBox(width: Dimensions.spaceL),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'المساحة التخزينية',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: Dimensions.spaceXS),
                      LinearProgressIndicator(
                        value: 0.65,
                        backgroundColor: AppColors.gray200,
                        color: AppColors.primary,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: Dimensions.spaceXS),
                      const Text(
                        '1.3 GB من 2 GB مستخدمة',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.upgrade),
                  onPressed: () {
                    _upgradeStorage();
                  },
                ),
              ],
            ),
          ),

          // Documents List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(Dimensions.spaceL),
              itemCount: 10,
              itemBuilder: (context, index) {
                final document = _getDocumentData(index);
                final isSelected = _selectedDocuments.contains(document['id']);

                return GestureDetector(
                  onLongPress: () {
                    setState(() {
                      if (isSelected) {
                        _selectedDocuments.remove(document['id']);
                      } else {
                        _selectedDocuments.add(document['id']!);
                      }
                    });
                  },
                  onTap: () {
                    if (_selectedDocuments.isNotEmpty) {
                      setState(() {
                        if (isSelected) {
                          _selectedDocuments.remove(document['id']);
                        } else {
                          _selectedDocuments.add(document['id']!);
                        }
                      });
                    } else {
                      _viewDocument(document);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: Dimensions.spaceL),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(Dimensions.radiusL),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: isSelected ? 10 : 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Document Header
                        Container(
                          padding: const EdgeInsets.all(Dimensions.spaceL),
                          decoration: BoxDecoration(
                            color: document['color']!.withOpacity(0.1),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(Dimensions.radiusL),
                              topRight: Radius.circular(Dimensions.radiusL),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: document['color'],
                                  borderRadius: BorderRadius.circular(
                                    Dimensions.radiusM,
                                  ),
                                ),
                                child: Icon(
                                  document['icon'],
                                  color: AppColors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: Dimensions.spaceL),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      document['name']!,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: Dimensions.spaceXS),
                                    Text(
                                      document['project']!,
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: AppColors.white,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Document Details
                        Padding(
                          padding: const EdgeInsets.all(Dimensions.spaceL),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    document['type']!,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (document['signed']!)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: Dimensions.spaceM,
                                        vertical: Dimensions.spaceXS,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          Dimensions.radiusS,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.verified,
                                            size: 12,
                                            color: AppColors.success,
                                          ),
                                          const SizedBox(
                                            width: Dimensions.spaceXS,
                                          ),
                                          Text(
                                            'موقعة',
                                            style: TextStyle(
                                              color: AppColors.success,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: Dimensions.spaceS),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 12,
                                        color: AppColors.textHint,
                                      ),
                                      const SizedBox(width: Dimensions.spaceXS),
                                      Text(
                                        document['date']!,
                                        style: TextStyle(
                                          color: AppColors.textHint,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.insert_drive_file,
                                        size: 12,
                                        color: AppColors.textHint,
                                      ),
                                      const SizedBox(width: Dimensions.spaceXS),
                                      Text(
                                        document['size']!,
                                        style: TextStyle(
                                          color: AppColors.textHint,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: Dimensions.spaceL),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        _downloadDocument(document);
                                      },
                                      icon: const Icon(Icons.download),
                                      label: const Text('تحميل'),
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size(0, 40),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: Dimensions.spaceM),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        _viewDocument(document);
                                      },
                                      icon: const Icon(Icons.visibility),
                                      label: const Text('عرض'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: AppColors.white,
                                        minimumSize: const Size(0, 40),
                                      ),
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
              },
            ),
          ),
        ],
      ),
      bottomSheet: _selectedDocuments.isNotEmpty
          ? Container(
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
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedDocuments.clear();
                        });
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('إلغاء التحديد'),
                    ),
                  ),
                  const SizedBox(width: Dimensions.spaceL),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _shareSelectedDocuments();
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('مشاركة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? value : 'all';
        });
      },
      selectedColor: AppColors.primary,
      checkmarkColor: AppColors.white,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.white : AppColors.textPrimary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
      ),
    );
  }

  Map<String, dynamic> _getDocumentData(int index) {
    final documents = [
      {
        'id': 'doc_1',
        'name': 'عقد شراكة المشروع',
        'project': 'برج النخيل السكني',
        'type': 'عقد',
        'date': '١٠ مارس ٢٠٢٤',
        'size': '2.1 MB',
        'color': AppColors.primary,
        'icon': Icons.contrast,
        'signed': true,
      },
      {
        'id': 'doc_2',
        'name': 'فاتورة الدفعة الأولى',
        'project': 'برج النخيل السكني',
        'type': 'فاتورة',
        'date': '٥ مارس ٢٠٢٤',
        'size': '1.5 MB',
        'color': AppColors.success,
        'icon': Icons.receipt,
        'signed': true,
      },
      {
        'id': 'doc_3',
        'name': 'تقرير التقدم الشهري',
        'project': 'برج النخيل السكني',
        'type': 'تقرير',
        'date': '١ مارس ٢٠٢٤',
        'size': '3.2 MB',
        'color': AppColors.info,
        'icon': Icons.assessment,
        'signed': false,
      },
      {
        'id': 'doc_4',
        'name': 'شهادة الجودة',
        'project': 'برج النخيل السكني',
        'type': 'شهادة',
        'date': '٢٥ فبراير ٢٠٢٤',
        'size': '1.8 MB',
        'color': AppColors.warning,
        'icon': Icons.verified,
        'signed': true,
      },
      {
        'id': 'doc_5',
        'name': 'مخططات هندسية',
        'project': 'برج النخيل السكني',
        'type': 'مخطط',
        'date': '٢٠ فبراير ٢٠٢٤',
        'size': '5.4 MB',
        'color': AppColors.error,
        'icon': Icons.architecture,
        'signed': true,
      },
    ];

    return documents[index % documents.length];
  }

  void _viewDocument(Map<String, dynamic> document) {
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
          height: MediaQuery.of(context).size.height * 0.9,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    document['name']!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.spaceL),
              // Document viewer would go here
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(Dimensions.radiusL),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          document['icon'],
                          size: 80,
                          color: document['color'],
                        ),
                        const SizedBox(height: Dimensions.spaceL),
                        const Text(
                          'عرض المستند',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: Dimensions.spaceS),
                        Text(
                          'سيتم فتح المستند في عارض PDF',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.spaceL),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _downloadDocument(document);
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('تحميل'),
                    ),
                  ),
                  const SizedBox(width: Dimensions.spaceL),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _printDocument(document);
                      },
                      icon: const Icon(Icons.print),
                      label: const Text('طباعة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.spaceL),
            ],
          ),
        );
      },
    );
  }

  void _downloadDocument(Map<String, dynamic> document) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تحميل المستند'),
          content: Text('هل تريد تحميل "${document['name']}"؟'),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('جاري تحميل ${document['name']}'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('تحميل'),
            ),
          ],
        );
      },
    );
  }

  void _printDocument(Map<String, dynamic> document) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('طباعة المستند'),
          content: Text('هل تريد طباعة "${document['name']}"؟'),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('جاري إعداد ${document['name']} للطباعة'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('طباعة'),
            ),
          ],
        );
      },
    );
  }

  void _uploadDocument() {
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
                'رفع مستند جديد',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: Dimensions.spaceL),
              Expanded(
                child: ListView(
                  children: [
                    // File Picker
                    GestureDetector(
                      onTap: () {
                        // Pick file
                      },
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusL,
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
                              Icons.cloud_upload,
                              size: 64,
                              color: AppColors.primary,
                            ),
                            SizedBox(height: Dimensions.spaceL),
                            Text(
                              'انقر لاختيار ملف',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: Dimensions.spaceS),
                            Text(
                              'PDF, DOC, PNG, JPG - الحد الأقصى 10MB',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: Dimensions.spaceL),
                    // Form
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'اسم المستند',
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: Dimensions.spaceL),
                    DropdownButtonFormField(
                      decoration: const InputDecoration(
                        labelText: 'نوع المستند',
                        filled: true,
                      ),
                      items: ['عقد', 'فاتورة', 'تقرير', 'شهادة', 'مخطط']
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {},
                    ),
                    const SizedBox(height: Dimensions.spaceL),
                    DropdownButtonFormField(
                      decoration: const InputDecoration(
                        labelText: 'المشروع',
                        filled: true,
                      ),
                      items: ['برج النخيل', 'مول التجارة', 'فيلات الريف']
                          .map(
                            (project) => DropdownMenuItem(
                              value: project,
                              child: Text(project),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {},
                    ),
                    const SizedBox(height: Dimensions.spaceL),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'وصف المستند',
                        filled: true,
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Dimensions.spaceL),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: Dimensions.spaceL),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم رفع المستند بنجاح'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                      ),
                      child: const Text('رفع'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.spaceL),
            ],
          ),
        );
      },
    );
  }

  void _deleteSelectedDocuments() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('حذف المستندات'),
          content: Text('هل تريد حذف ${_selectedDocuments.length} مستندات؟'),
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
                setState(() {
                  _selectedDocuments.clear();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('تم حذف المستندات'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );
  }

  void _shareSelectedDocuments() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Dimensions.radiusXL),
        ),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(Dimensions.spaceL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                'مشاركة المستندات',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: Dimensions.spaceL),
              const Text('اختر طريقة المشاركة:'),
              const SizedBox(height: Dimensions.spaceL),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 4,
                mainAxisSpacing: Dimensions.spaceL,
                crossAxisSpacing: Dimensions.spaceL,
                children: [
                  _buildShareOption(Icons.email, 'بريد', Colors.red),
                  _buildShareOption(Icons.cloud, 'سحابة', Colors.blue),
                  _buildShareOption(Icons.link, 'رابط', Colors.green),
                  _buildShareOption(Icons.print, 'طباعة', Colors.orange),
                ],
              ),
              const SizedBox(height: Dimensions.spaceL),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShareOption(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        const SizedBox(height: Dimensions.spaceS),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  void _upgradeStorage() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ترقية المساحة التخزينية'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('اختر خطة التخزين:'),
              const SizedBox(height: Dimensions.spaceL),
              _buildStorageOption('5 GB', 'شهرياً', '50 ج.م'),
              _buildStorageOption('20 GB', 'سنوياً', '400 ج.م'),
              _buildStorageOption('100 GB', 'مدى الحياة', '1000 ج.م'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('لاحقاً'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStorageOption(String size, String period, String price) {
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.spaceM),
      padding: const EdgeInsets.all(Dimensions.spaceL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.storage, color: AppColors.primary),
          const SizedBox(width: Dimensions.spaceL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(size, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  period,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
