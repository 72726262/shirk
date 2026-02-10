import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/cubits/handover/handover_state.dart';
import 'package:mmm/presentation/widgets/common/primary_button.dart';
import 'package:mmm/presentation/cubits/handover/handover_cubit.dart';
import 'package:mmm/routes/route_names.dart';
import 'package:table_calendar/table_calendar.dart';

class BookAppointmentScreen extends StatefulWidget {
  final String unitId;

  const BookAppointmentScreen({super.key, required this.unitId});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  String? _selectedTimeSlot;

  final List<String> _timeSlots = [
    '09:00 - 10:00',
    '10:00 - 11:00',
    '11:00 - 12:00',
    '14:00 - 15:00',
    '15:00 - 16:00',
    '16:00 - 17:00',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('حجز موعد المعاينة'),
        backgroundColor: AppColors.primary,
      ),
      body: BlocConsumer<HandoverCubit, HandoverState>(
        listener: (context, state) {
          if (state is AppointmentBooked) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم حجز الموعد بنجاح'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is HandoverLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(Dimensions.spaceXXL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Calendar
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(Dimensions.radiusL),
                  ),
                  child: TableCalendar(
                    firstDay: DateTime.now(),
                    lastDay: DateTime.now().add(const Duration(days: 30)),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                        _selectedTimeSlot = null;
                      });
                    },
                    calendarStyle: const CalendarStyle(
                      selectedDecoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: AppColors.info,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Dimensions.spaceXL),

                // Time Slots
                Text(
                  'اختر الوقت المناسب',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
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
                      onSelected: isLoading
                          ? null
                          : (selected) {
                              setState(
                                () =>
                                    _selectedTimeSlot = selected ? slot : null,
                              );
                            },
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppColors.white
                            : AppColors.textPrimary,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: Dimensions.spaceXXL),

                // Confirm Button
                PrimaryButton(
                  text: 'تأكيد الموعد',
                  onPressed: _selectedTimeSlot != null && !isLoading
                      ? _confirmAppointment
                      : null,
                  isLoading: isLoading,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmAppointment() async {
    if (_selectedTimeSlot == null) return;

    // Parse time slot to get hour
    final timeParts = _selectedTimeSlot!.split(' - ')[0].split(':');
    final hour = int.parse(timeParts[0]);
    final appointmentDate = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
      hour,
    );

    await context.read<HandoverCubit>().bookAppointmentForUnit(
      unitId: widget.unitId,
      appointmentDate: appointmentDate,
    );
  }
}
