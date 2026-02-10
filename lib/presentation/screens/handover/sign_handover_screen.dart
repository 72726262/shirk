import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/presentation/cubits/handover/handover_state.dart';
import 'package:mmm/presentation/widgets/common/primary_button.dart';
import 'package:mmm/presentation/widgets/custom/signature_pad.dart';
import 'package:mmm/presentation/cubits/handover/handover_cubit.dart';
import 'package:mmm/routes/route_names.dart';

class SignHandoverScreen extends StatefulWidget {
  final String unitId;

  const SignHandoverScreen({super.key, required this.unitId});

  @override
  State<SignHandoverScreen> createState() => _SignHandoverScreenState();
}

class _SignHandoverScreenState extends State<SignHandoverScreen> {
  final _signatureKey = GlobalKey<SignaturePadWidgetState>();
  bool _hasSignature = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('التوقيع على استلام الوحدة'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _signatureKey.currentState?.clear();
              setState(() => _hasSignature = false);
            },
          ),
        ],
      ),
      body: BlocConsumer<HandoverCubit, HandoverState>(
        listener: (context, state) {
          if (state is HandoverCompleted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              RouteNames.handoverConfirmation,
              (route) => false,
              arguments: widget.unitId,
            );
          }
        },
        builder: (context, state) {
          final isSubmitting = state is HandoverLoading;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(Dimensions.spaceXXL),
                  child: Column(
                    children: [
                      Icon(Icons.draw, size: 60, color: AppColors.primary),
                      const SizedBox(height: Dimensions.spaceL),
                      Text(
                        'التوقيع على استلام الوحدة',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: Dimensions.spaceM),
                      Text(
                        'بتوقيعك أدناه، أنت تؤكد استلام الوحدة بحالة جيدة',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: Dimensions.spaceXXL),

                      // Signature Pad
                      Container(
                        height: 300,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusL,
                          ),
                          border: Border.all(color: AppColors.border, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusL,
                          ),
                          child: SignaturePadWidget(
                            key: _signatureKey,
                            onSigned: (signature) {
                              setState(() => _hasSignature = signature != null);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Actions
              Container(
                padding: const EdgeInsets.all(Dimensions.spaceL),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: PrimaryButton(
                    text: 'تأكيد الاستلام',
                    onPressed: _hasSignature && !isSubmitting
                        ? _submitSignature
                        : null,
                    isLoading: isSubmitting,
                    leadingIcon: Icons.check,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submitSignature() async {
    final signatureData = await _signatureKey.currentState?.getSignature();
    if (signatureData == null) return;
    if (!mounted) return;

    await context.read<HandoverCubit>().completeHandover(
      widget.unitId,
      signatureData.toString(),
    );
  }
}
