import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'dart:math' as math;

class KycApprovalDialog extends StatefulWidget {
  const KycApprovalDialog({super.key});

  @override
  State<KycApprovalDialog> createState() => _KycApprovalDialogState();
}

class _KycApprovalDialogState extends State<KycApprovalDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: math.pi * 2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5),
      ),
    );

    _controller.forward();

    // Auto dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.success.withOpacity(0.95),
                      AppColors.success.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated checkmark with 3D effect
                    Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(_rotationAnimation.value),
                      alignment: Alignment.center,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          size: 80,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Title with glow effect
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Text(
                        '🎉 تم الموافقة على حسابك!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Subtitle
                    const Text(
                      'يمكنك الآن الاستمتاع بجميع ميزات المنصة',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Animated progress indicator
                    SizedBox(
                      width: 200,
                      child: LinearProgressIndicator(
                        value: _controller.value,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Helper function to show the dialog
Future<void> showKycApprovalDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (context) => const KycApprovalDialog(),
  );
}
