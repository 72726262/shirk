import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/project_model.dart';

class SelectUnitScreen extends StatefulWidget {
  final String projectId;
  final ProjectModel? project; // اختياري

  const SelectUnitScreen({super.key, required this.projectId, this.project});

  @override
  State<SelectUnitScreen> createState() => _SelectUnitScreenState();
}

class _SelectUnitScreenState extends State<SelectUnitScreen> {
  String? _selectedUnitId;
  bool _viewMode = false; // false = grid, true = list

  // Dummy units data
  final List<Map<String, dynamic>> _units = [
    {
      'id': 'unit_1',
      'number': 'A101',
      'type': 'شقة',
      'area': 120,
      'price': 1200000,
      'floor': '1',
      'building': 'A',
      'view': 'جنوبي',
      'status': 'متاح',
      'features': ['3 غرف', '2 حمام', 'مطبخ', 'ريسبشن'],
    },
    {
      'id': 'unit_2',
      'number': 'A102',
      'type': 'شقة',
      'area': 150,
      'price': 1500000,
      'floor': '1',
      'building': 'A',
      'view': 'شمالي',
      'status': 'متاح',
      'features': ['4 غرف', '3 حمام', 'مطبخ', '2 ريسبشن'],
    },
    {
      'id': 'unit_3',
      'number': 'B201',
      'type': 'دوبلكس',
      'area': 200,
      'price': 2500000,
      'floor': '2',
      'building': 'B',
      'view': 'جنوبي',
      'status': 'محجوز',
      'features': ['5 غرف', '4 حمام', 'مطبخ', '3 ريسبشن', 'حديقة'],
    },
    {
      'id': 'unit_4',
      'number': 'C301',
      'type': 'بنتهاوس',
      'area': 300,
      'price': 4000000,
      'floor': '3',
      'building': 'C',
      'view': 'بانورامي',
      'status': 'متاح',
      'features': ['6 غرف', '5 حمام', 'مطبخين', '4 ريسبشن', 'ساونا', 'جيم'],
    },
    {
      'id': 'unit_5',
      'number': 'A103',
      'type': 'شقة',
      'area': 100,
      'price': 900000,
      'floor': '1',
      'building': 'A',
      'view': 'غربي',
      'status': 'متاح',
      'features': ['2 غرف', '2 حمام', 'مطبخ', 'ريسبشن'],
    },
    {
      'id': 'unit_6',
      'number': 'B202',
      'type': 'شقة',
      'area': 180,
      'price': 2000000,
      'floor': '2',
      'building': 'B',
      'view': 'شرقي',
      'status': 'متاح',
      'features': ['4 غرف', '3 حمام', 'مطبخ', '2 ريسبشن'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختيار الوحدة'),
        actions: [
          IconButton(
            icon: Icon(_viewMode ? Icons.grid_view : Icons.list),
            onPressed: () {
              setState(() {
                _viewMode = !_viewMode;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(Dimensions.spaceL),
            color: AppColors.surface,
            child: Column(
              children: [
                // Quick Filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('جميع الوحدات'),
                        selected: true,
                        onSelected: (selected) {},
                      ),
                      const SizedBox(width: Dimensions.spaceS),
                      FilterChip(
                        label: const Text('متاحة فقط'),
                        selected: false,
                        onSelected: (selected) {},
                      ),
                      const SizedBox(width: Dimensions.spaceS),
                      FilterChip(
                        label: const Text('الشقق'),
                        selected: false,
                        onSelected: (selected) {},
                      ),
                      const SizedBox(width: Dimensions.spaceS),
                      FilterChip(
                        label: const Text('الدوبلكس'),
                        selected: false,
                        onSelected: (selected) {},
                      ),
                      const SizedBox(width: Dimensions.spaceS),
                      FilterChip(
                        label: const Text('أقل من 1.5 مليون'),
                        selected: false,
                        onSelected: (selected) {},
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: Dimensions.spaceL),

                // Building/Floor Filter
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField(
                        decoration: const InputDecoration(
                          labelText: 'المبنى',
                          filled: true,
                        ),
                        items: ['الكل', 'A', 'B', 'C']
                            .map(
                              (building) => DropdownMenuItem(
                                value: building,
                                child: Text(building),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {},
                      ),
                    ),
                    const SizedBox(width: Dimensions.spaceL),
                    Expanded(
                      child: DropdownButtonFormField(
                        decoration: const InputDecoration(
                          labelText: 'الدور',
                          filled: true,
                        ),
                        items: ['الكل', '1', '2', '3', '4']
                            .map(
                              (floor) => DropdownMenuItem(
                                value: floor,
                                child: Text(floor),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {},
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Units List/Grid
          Expanded(child: _viewMode ? _buildUnitsList() : _buildUnitsGrid()),

          // Selected Unit Summary
          if (_selectedUnitId != null) ...[
            Container(
              padding: const EdgeInsets.all(Dimensions.spaceL),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),

                border: const Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'الوحدة المحددة',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: Dimensions.spaceXS),
                        Text(
                          _getSelectedUnit()['number'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${_getSelectedUnit()['price']?.toStringAsFixed(0) ?? ''} ج.م',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/contract-summary',
                        arguments: {
                          'projectId': widget.projectId,
                          'unitId': _selectedUnitId,
                        },
                      );
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('التالي'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUnitsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: Dimensions.spaceL,
        mainAxisSpacing: Dimensions.spaceL,
        childAspectRatio: 0.9,
      ),
      itemCount: _units.length,
      itemBuilder: (context, index) {
        final unit = _units[index];
        final isSelected = _selectedUnitId == unit['id'];
        final isAvailable = unit['status'] == 'متاح';

        return GestureDetector(
          onTap: isAvailable
              ? () {
                  setState(() {
                    _selectedUnitId = unit['id'];
                  });
                }
              : null,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(Dimensions.radiusL),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),

                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Unit Image and Status
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.gray200,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(Dimensions.radiusL),
                      topRight: Radius.circular(Dimensions.radiusL),
                    ),
                    image: DecorationImage(
                      image: NetworkImage(
                        'https://via.placeholder.com/200x100/102289/FFFFFF?text=Unit+${unit['number']}',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Status Badge
                      Positioned(
                        top: Dimensions.spaceM,
                        left: Dimensions.spaceM,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.spaceM,
                            vertical: Dimensions.spaceXS,
                          ),
                          decoration: BoxDecoration(
                            color: isAvailable
                                ? AppColors.success.withOpacity(0.9)
                                : AppColors.error.withOpacity(0.9),

                            borderRadius: BorderRadius.circular(
                              Dimensions.radiusS,
                            ),
                          ),
                          child: Text(
                            unit['status'],
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      // Selected Indicator
                      if (isSelected)
                        Positioned(
                          top: Dimensions.spaceM,
                          right: Dimensions.spaceM,
                          child: Container(
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
                        ),
                    ],
                  ),
                ),

                // Unit Details
                Padding(
                  padding: const EdgeInsets.all(Dimensions.spaceM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الوحدة ${unit['number']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: Dimensions.spaceXS),
                      Text(
                        '${unit['type']} • ${unit['area']} م²',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: Dimensions.spaceXS),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 12,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(width: Dimensions.spaceXS),
                          Text(
                            'مبنى ${unit['building']} - دور ${unit['floor']}',
                            style: TextStyle(
                              color: AppColors.textHint,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Dimensions.spaceS),
                      Text(
                        '${unit['price']?.toStringAsFixed(0) ?? ''} ج.م',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: Dimensions.spaceXS),
                      Text(
                        '${(unit['price']! / 120).toStringAsFixed(0)} ج.م/م²',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUnitsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(Dimensions.spaceL),
      itemCount: _units.length,
      itemBuilder: (context, index) {
        final unit = _units[index];
        final isSelected = _selectedUnitId == unit['id'];
        final isAvailable = unit['status'] == 'متاح';

        return GestureDetector(
          onTap: isAvailable
              ? () {
                  setState(() {
                    _selectedUnitId = unit['id'];
                  });
                }
              : null,
          child: Container(
            margin: const EdgeInsets.only(bottom: Dimensions.spaceL),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(Dimensions.radiusL),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Unit Image
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.gray200,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(Dimensions.radiusL),
                      bottomRight: Radius.circular(Dimensions.radiusL),
                    ),
                    image: DecorationImage(
                      image: NetworkImage(
                        'https://via.placeholder.com/120x120/102289/FFFFFF?text=Unit',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: !isAvailable
                      ? Container(
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.3),

                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(Dimensions.radiusL),
                              bottomRight: Radius.circular(Dimensions.radiusL),
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.lock,
                              color: AppColors.white,
                              size: 32,
                            ),
                          ),
                        )
                      : null,
                ),

                // Unit Details
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(Dimensions.spaceL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'الوحدة ${unit['number']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Dimensions.spaceM,
                                vertical: Dimensions.spaceXS,
                              ),
                              decoration: BoxDecoration(
                                color: isAvailable
                                    ? AppColors.success.withOpacity(0.1)
                                    : AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(
                                  Dimensions.radiusS,
                                ),
                              ),
                              child: Text(
                                unit['status'],
                                style: TextStyle(
                                  color: isAvailable
                                      ? AppColors.success
                                      : AppColors.error,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Dimensions.spaceXS),
                        Text(
                          '${unit['type']} • ${unit['area']} م² • ${unit['view']}',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: Dimensions.spaceXS),
                        Text(
                          'مبنى ${unit['building']} - دور ${unit['floor']}',
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: Dimensions.spaceM),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${unit['price']?.toStringAsFixed(0) ?? ''} ج.م',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.primary,
                                size: 24,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Map<String, dynamic> _getSelectedUnit() {
    return _units.firstWhere(
      (unit) => unit['id'] == _selectedUnitId,
      orElse: () => {},
    );
  }
}
