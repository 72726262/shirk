import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';

class PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;
  final bool fullWidth;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? disabledColor;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;
  final TextStyle? textStyle;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final double elevation;
  final Duration? animationDuration;
  final Curve animationCurve;
  final BoxShadow? customShadow;

  const PrimaryButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.fullWidth = true,
    this.backgroundColor,
    this.foregroundColor,
    this.disabledColor,
    this.height,
    this.width,
    this.padding,
    this.borderRadius,
    this.textStyle,
    this.leadingIcon,
    this.trailingIcon,
    this.elevation = 0,
    this.animationDuration,
    this.animationCurve = Curves.easeInOut,
    this.customShadow,
  });

  // Constructor للاستخدام السريع بدون أيقونات
  factory PrimaryButton.simple({
    Key? key,
    required VoidCallback? onPressed,
    required String text,
    bool isLoading = false,
    bool fullWidth = true,
  }) {
    return PrimaryButton(
      key: key,
      onPressed: onPressed,
      text: text,
      isLoading: isLoading,
      fullWidth: fullWidth,
    );
  }

  // Constructor للزر مع أيقونة في البداية
  factory PrimaryButton.withIcon({
    Key? key,
    required VoidCallback? onPressed,
    required String text,
    required IconData icon,
    bool isLoading = false,
    bool fullWidth = true,
    bool iconAtStart = true,
  }) {
    return PrimaryButton(
      key: key,
      onPressed: onPressed,
      text: text,
      isLoading: isLoading,
      fullWidth: fullWidth,
      leadingIcon: iconAtStart ? icon : null,
      trailingIcon: !iconAtStart ? icon : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    return AnimatedContainer(
      duration: animationDuration ?? const Duration(milliseconds: 300),
      curve: animationCurve,
      width: fullWidth ? double.infinity : width,
      height: height ?? Dimensions.buttonHeight,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(Dimensions.radiusL),
        boxShadow: isEnabled && elevation > 0
            ? [
                customShadow ??
                    BoxShadow(
                      color: (backgroundColor ?? AppColors.primary).withOpacity(
                        0.3,
                      ),
                      blurRadius: elevation * 2,
                      offset: Offset(0, elevation),
                    ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primary,
          foregroundColor: foregroundColor ?? AppColors.white,
          disabledBackgroundColor:
              disabledColor ??
              (backgroundColor ?? AppColors.primary).withOpacity(0.5),
          disabledForegroundColor: (foregroundColor ?? AppColors.white)
              .withOpacity(0.7),
          padding:
              padding ??
              const EdgeInsets.symmetric(
                horizontal: Dimensions.spaceXL,
                vertical: Dimensions.spaceM,
              ),
          shape: RoundedRectangleBorder(
            borderRadius:
                borderRadius ?? BorderRadius.circular(Dimensions.radiusL),
          ),
          elevation: 0,
          animationDuration: animationDuration,
        ),
        child: _buildButtonContent(),
      ),
    );
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: foregroundColor ?? AppColors.white,
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leadingIcon != null) ...[
          Icon(
            leadingIcon,
            size: 20,
            color: foregroundColor ?? AppColors.white,
          ),
          const SizedBox(width: Dimensions.spaceM),
        ],
        Flexible(
          child: Text(
            text,
            style:
                textStyle ??
                TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: foregroundColor ?? AppColors.white,
                  letterSpacing: 0.5,
                ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: Dimensions.spaceM),
          Icon(
            trailingIcon,
            size: 20,
            color: foregroundColor ?? AppColors.white,
          ),
        ],
      ],
    );
  }
}

// ---------- Optional: Secondary Button Variation ----------
class SecondaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;
  final bool fullWidth;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final double? height;
  final double? width;

  const SecondaryButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.fullWidth = true,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      onPressed: onPressed,
      text: text,
      isLoading: isLoading,
      fullWidth: fullWidth,
      height: height,
      width: width,
      backgroundColor: backgroundColor ?? AppColors.white,
      foregroundColor: textColor ?? AppColors.primary,
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.spaceXL,
        vertical: Dimensions.spaceM,
      ),
      borderRadius: BorderRadius.circular(Dimensions.radiusL),
      elevation: 0,
      textStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor ?? AppColors.primary,
      ),
    );
  }
}

// ---------- Optional: Text Button Variation ----------
class TextButtonStyled extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final Color? color;
  final bool underline;
  final TextStyle? style;

  const TextButtonStyled({
    super.key,
    required this.onPressed,
    required this.text,
    this.color,
    this.underline = false,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        text,
        style:
            style ??
            TextStyle(
              fontSize: 14,
              color: color ?? AppColors.primary,
              fontWeight: FontWeight.w500,
              decoration: underline ? TextDecoration.underline : null,
              decorationColor: color ?? AppColors.primary,
            ),
      ),
    );
  }
}
