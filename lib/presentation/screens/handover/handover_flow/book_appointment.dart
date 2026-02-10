import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';

import 'package:table_calendar/table_calendar.dart';

class BookAppointmentScreen extends StatefulWidget {
  final String projectId;
  final String unitId;

  const BookAppointmentScreen({
    super.key,
    required this.projectId,
    required this.unitId,
  });

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  // CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _selectedTimeSlot = '';
  int _numberOfAttendees = 1;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  final List<String> _timeSlots = [
    '9:00 ص - 10:00 ص',
    '10:00 ص - 11:00 ص',
    '11:00 ص - 12:00 م',
    '1:00 م - 2:00 م',
    '2:00 م - 3:00 م',
    '3:00 م - 4:00 م',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حجز موعد الاستلام')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Info
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
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(Dimensions.radiusL),
                    ),
                    child: const Icon(
                      Icons.assignment_turned_in,
                      color: AppColors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: Dimensions.spaceL),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'موعد استلام الوحدة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'برج النخيل - الوحدة A101',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Calendar Section
            Padding(
              padding: const EdgeInsets.all(Dimensions.spaceL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'اختر التاريخ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: Dimensions.spaceL),
                  Container(
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
                    child: TableCalendar(
                      firstDay: DateTime.now(),
                      lastDay: DateTime.now().add(const Duration(days: 60)),
                      focusedDay: _focusedDay,
                      calendarFormat: _calendarFormat,
                      selectedDayPredicate: (day) {
                        return isSameDay(_selectedDay, day);
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      onFormatChanged: (format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                      },
                      calendarStyle: CalendarStyle(
                        selectedDecoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary),
                        ),
                        selectedTextStyle: const TextStyle(
                          color: AppColors.white,
                        ),
                        weekendTextStyle: const TextStyle(
                          color: AppColors.error,
                        ),
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      daysOfWeekStyle: const DaysOfWeekStyle(
                        weekdayStyle: TextStyle(fontWeight: FontWeight.bold),
                        weekendStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                      locale: 'ar',
                    ),
                  ),
                ],
              ),
            ),

            // Time Slots
            Padding(
              padding: const EdgeInsets.all(Dimensions.spaceL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'اختر الوقت',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: Dimensions.spaceL),
                  Wrap(
                    spacing: Dimensions.spaceM,
                    runSpacing: Dimensions.spaceM,
                    children: _timeSlots.map((slot) {
                      final isSelected = _selectedTimeSlot == slot;
                      return ChoiceChip(
                        label: Text(slot),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedTimeSlot = selected ? slot : '';
                          });
                        },
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.white
                              : AppColors.textPrimary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusL,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // Attendees
            Padding(
              padding: const EdgeInsets.all(Dimensions.spaceL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'عدد الحضور',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: Dimensions.spaceL),
                  Container(
                    padding: const EdgeInsets.all(Dimensions.spaceL),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(Dimensions.radiusL),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            setState(() {
                              if (_numberOfAttendees > 1) {
                                _numberOfAttendees--;
                              }
                            });
                          },
                          color: AppColors.primary,
                        ),
                        Text(
                          '$_numberOfAttendees شخص',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            setState(() {
                              if (_numberOfAttendees < 5) {
                                _numberOfAttendees++;
                              }
                            });
                          },
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Dimensions.spaceS),
                  Text(
                    'الحد الأقصى: 5 أشخاص',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
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
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Dimensions.radiusL),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.warning),
                    const SizedBox(width: Dimensions.spaceL),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ملاحظات هامة',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.warning,
                            ),
                          ),
                          const SizedBox(height: Dimensions.spaceS),
                          Text(
                            '• يرجى الحضور قبل الموعد بـ 15 دقيقة\n'
                            '• إحضار بطاقة الهوية الوطنية\n'
                            '• يحق للشركة تغيير الموعد في حال الطوارئ\n'
                            '• مدة الجلسة: ساعة واحدة',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
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
          onPressed: _selectedDay != null && _selectedTimeSlot.isNotEmpty
              ? () {
                  _confirmAppointment();
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
            'تأكيد الحجز',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  void _confirmAppointment() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تأكيد الحجز'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('تفاصيل الموعد:'),
              const SizedBox(height: Dimensions.spaceL),
              _buildAppointmentDetail('التاريخ', _formatDate(_selectedDay!)),
              _buildAppointmentDetail('الوقت', _selectedTimeSlot),
              _buildAppointmentDetail(
                'عدد الحضور',
                '$_numberOfAttendees أشخاص',
              ),
              const SizedBox(height: Dimensions.spaceL),
              Container(
                padding: const EdgeInsets.all(Dimensions.spaceM),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Dimensions.radiusM),
                ),
                child: const Text(
                  'سيتم إرسال تأكيد الحجز عبر البريد والرسائل النصية',
                  style: TextStyle(fontSize: 12, color: AppColors.success),
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
                Navigator.pop(context);
                _showAppointmentSuccess();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('تأكيد'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppointmentDetail(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.spaceXS),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAppointmentSuccess() {
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
                    Icons.calendar_today,
                    size: 48,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: Dimensions.spaceXL),
                const Text(
                  'تم الحجز بنجاح!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: Dimensions.spaceL),
                Text(
                  'تم حجز موعد الاستلام في $_selectedTimeSlot',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: Dimensions.spaceL),
                Container(
                  padding: const EdgeInsets.all(Dimensions.spaceL),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(Dimensions.radiusL),
                  ),
                  child: Column(
                    children: [
                      _buildSuccessDetail(
                        'رقم الحجز',
                        'APT${DateTime.now().millisecondsSinceEpoch}',
                      ),
                      _buildSuccessDetail(
                        'التاريخ',
                        _formatDate(_selectedDay!),
                      ),
                      _buildSuccessDetail('الوقت', _selectedTimeSlot),
                      _buildSuccessDetail(
                        'المكان',
                        'مكتب الاستلام - برج النخيل',
                      ),
                    ],
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
                        '/upload-snag-list',
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
                    child: const Text('التالي: قائمة العيوب'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuccessDetail(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.spaceS),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
