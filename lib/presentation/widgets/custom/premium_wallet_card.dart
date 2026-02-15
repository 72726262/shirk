import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';
import 'package:mmm/data/models/wallet_model.dart';

class Premium3DWalletCard extends StatefulWidget {
  final WalletModel wallet;
  final VoidCallback onAddFunds;
  final VoidCallback onWithdraw;
  final VoidCallback? onTransfer;

  const Premium3DWalletCard({
    super.key,
    required this.wallet,
    required this.onAddFunds,
    required this.onWithdraw,
    this.onTransfer,
  });

  @override
  State<Premium3DWalletCard> createState() => _Premium3DWalletCardState();
}

class _Premium3DWalletCardState extends State<Premium3DWalletCard>
    with TickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isBack = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flipAnimation = Tween<double>(begin: 0, end: math.pi).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isBack) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() {
      _isBack = !_isBack;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 3D Card with flip animation
        GestureDetector(
          onTap: _flipCard,
          child: AnimatedBuilder(
            animation: _flipAnimation,
            builder: (context, child) {
              final angle = _flipAnimation.value;
              final isUnder = angle > math.pi / 2;
              
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // Perspective
                  ..rotateY(angle),
                child: isUnder
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(math.pi),
                        child: _buildCardBack(),
                      )
                    : _buildCardFront(),
              );
            },
          ),
        ),
        
        const SizedBox(height: Dimensions.spaceL),
        
        // Quick Actions
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.add_circle_outline,
                label: 'إيداع',
                color: AppColors.success,
                onTap: widget.onAddFunds,
              ),
            ),
            const SizedBox(width: Dimensions.spaceM),
            Expanded(
              child: _buildActionButton(
                icon: Icons.remove_circle_outline,
                label: 'سحب',
                color: AppColors.error,
                onTap: widget.onWithdraw,
              ),
            ),
            if (widget.onTransfer != null) ...[
              const SizedBox(width: Dimensions.spaceM),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.swap_horiz,
                  label: 'تحويل',
                  color: AppColors.info,
                  onTap: widget.onTransfer!,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildCardFront() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusXL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            offset: const Offset(0, 20),
            blurRadius: 40,
            spreadRadius: -10,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 10),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.6),
            AppColors.primary.withOpacity(0.8),
            AppColors.primary,
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Dimensions.radiusXL),
        child: Stack(
          children: [
            // Glassmorphism background effect
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                ),
              ),
            ),
            
            // Circuit pattern overlay
            Positioned.fill(
              child: CustomPaint(
                painter: CircuitPatternPainter(),
              ),
            ),
            
            // Card Content
            Padding(
              padding: const EdgeInsets.all(Dimensions.spaceL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo and contactless
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLogo(),
                      Icon(
                        Icons.contactless_outlined,
                        color: Colors.white.withOpacity(0.8),
                        size: 28,
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Chip
                  _buildChip(),
                  
                  const SizedBox(height: Dimensions.spaceS),
                  
                  // Card Number
                  Text(
                    _formatCardNumber(widget.wallet.id),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                  
                  const SizedBox(height: Dimensions.spaceXS),
                  
                  // Balance and Name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الرصيد المتاح',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.wallet.balance.toStringAsFixed(2)} ر.س',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'صالح حتى',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '12/28',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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

  Widget _buildCardBack() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusXL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            offset: const Offset(0, 20),
            blurRadius: 40,
            spreadRadius: -10,
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            AppColors.primary.withOpacity(0.9),
            AppColors.primary,
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Dimensions.radiusXL),
        child: Column(
          children: [
            const SizedBox(height: 30),
            
            // Magnetic Stripe
            Container(
              height: 50,
              color: Colors.black87,
            ),
            
            const Spacer(),
            
            // Signature Panel
            Padding(
              padding: const EdgeInsets.all(Dimensions.spaceXL),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: const Text(
                        'Signature',
                        style: TextStyle(
                          color: Colors.black54,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 60,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '***',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: Dimensions.spaceM),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'شريك',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildChip() {
    return Container(
      width: 45,
      height: 35,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber.withOpacity(0.9),
            Colors.amber.shade700,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.4),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CustomPaint(
          painter: ChipPatternPainter(),
        ),
      ),
    );
  }

  String _formatCardNumber(String id) {
    // Take last 16 characters and format as ****  ****  ****  1234
    final sanitized = id.replaceAll(RegExp(r'[^0-9a-f]'), '').toUpperCase();
    final last4 = sanitized.length >= 4 ? sanitized.substring(sanitized.length - 4) : '0000';
    return '****  ****  ****  $last4';
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimensions.radiusL),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: Dimensions.spaceM),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(Dimensions.radiusL),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: Dimensions.spaceXS),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom painter for circuit pattern
class CircuitPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw random circuit-like lines
    for (var i = 0; i < 20; i++) {
      final path = Path();
      path.moveTo(size.width * (i * 0.05), 0);
      path.lineTo(size.width * (i * 0.05), size.height * 0.3);
      path.lineTo(size.width * ((i + 1) * 0.05), size.height * 0.5);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for chip hologram effect
class ChipPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Draw grid pattern
    for (var i = 1; i < 6; i++) {
      canvas.drawLine(
        Offset(size.width * (i / 6), 0),
        Offset(size.width * (i / 6), size.height),
        paint,
      );
    }
    for (var i = 1; i < 5; i++) {
      canvas.drawLine(
        Offset(0, size.height * (i / 5)),
        Offset(size.width, size.height * (i / 5)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
