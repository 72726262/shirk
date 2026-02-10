import 'package:flutter/material.dart';
import 'package:mmm/core/constants/colors.dart';
import 'package:mmm/core/constants/dimensions.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final Widget? suffixIconWidget; // جديد: إضافة widget كامل للـ suffix
  final VoidCallback? onSuffixIconTap;
  final VoidCallback? onTap; // جديد: عند الضغط على الحقل
  final bool enabled;
  final int? maxLines;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final bool readOnly; // جديد: للقراءة فقط
  final FocusNode? focusNode; // جديد: لإدارة التركيز
  final Color? prefixIconColor; // جديد: لون أيقونة البادئة
  final Color? suffixIconColor; // جديد: لون أيقونة اللاحقة
  final InputBorder? enabledBorder; // جديد: border عند التفعيل
  final InputBorder? focusedBorder; // جديد: border عند التركيز
  final InputBorder? errorBorder; // جديد: border عند الخطأ
  final InputBorder? focusedErrorBorder; // جديد: border عند التركيز مع خطأ
  final Color? fillColor; // جديد: لون التعبئة
  final bool? filled; // جديد: هل تم تعبئة الحقل
  final EdgeInsetsGeometry? contentPadding; // جديد: padding مخصص
  final BoxConstraints? prefixIconConstraints; // جديد: قيود حجم البادئة
  final BoxConstraints? suffixIconConstraints; // جديد: قيود حجم اللاحقة
  final TextStyle? labelStyle; // جديد: ستايل التسمية
  final TextStyle? hintStyle; // جديد: ستايل التلميح
  final TextStyle? textStyle; // جديد: ستايل النص
  final TextCapitalization textCapitalization; // جديد: تحويل النص
  final bool showLabel; // جديد: عرض التسمية أو إخفاؤها
  final String? errorText; // جديد: نص الخطأ المخصص
  final bool showCounter; // جديد: عرض عداد الأحرف
  final bool expands; // جديد: التوسع الرأسي
  final TextAlign textAlign; // جديد: محاذاة النص
  final TextAlignVertical? textAlignVertical; // جديد: محاذاة رأسية
  final AutovalidateMode? autovalidateMode; // جديد: وضع التحقق التلقائي
  final bool enableInteractiveSelection; // جديد: تفعيل التحديد التفاعلي
  final double? cursorHeight; // جديد: ارتفاع المؤشر
  final Color? cursorColor; // جديد: لون المؤشر

  const CustomTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.suffixIconWidget,
    this.onSuffixIconTap,
    this.onTap,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.textInputAction,
    this.readOnly = false,
    this.focusNode,
    this.prefixIconColor,
    this.suffixIconColor,
    this.enabledBorder,
    this.focusedBorder,
    this.errorBorder,
    this.focusedErrorBorder,
    this.fillColor,
    this.filled,
    this.contentPadding,
    this.prefixIconConstraints,
    this.suffixIconConstraints,
    this.labelStyle,
    this.hintStyle,
    this.textStyle,
    this.textCapitalization = TextCapitalization.none,
    this.showLabel = true,
    this.errorText,
    this.showCounter = false,
    this.expands = false,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.autovalidateMode,
    this.enableInteractiveSelection = true,
    this.cursorHeight,
    this.cursorColor,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _isObscured = true;
  late FocusNode _internalFocusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = widget.focusNode ?? FocusNode();
    _internalFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    } else {
      _internalFocusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _internalFocusNode.hasFocus;
    });
  }

  Widget? _buildSuffixIcon() {
    if (widget.suffixIconWidget != null) {
      return widget.suffixIconWidget;
    }

    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
          _isObscured
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: widget.suffixIconColor ?? AppColors.textSecondary,
        ),
        onPressed: () {
          setState(() {
            _isObscured = !_isObscured;
          });
          widget.onSuffixIconTap?.call();
        },
        splashRadius: 20,
      );
    }

    if (widget.suffixIcon != null) {
      return IconButton(
        icon: Icon(
          widget.suffixIcon,
          color: widget.suffixIconColor ?? AppColors.textSecondary,
        ),
        onPressed: widget.onSuffixIconTap,
        splashRadius: 20,
      );
    }

    return null;
  }

  InputBorder _getDefaultBorder({Color? color, double width = 1.0}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(Dimensions.inputBorderRadius),
      borderSide: BorderSide(color: color ?? AppColors.border, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPasswordField = widget.obscureText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showLabel) ...[
          Text(
            widget.label,
            style:
                widget.labelStyle ??
                Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _isFocused ? AppColors.primary : AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: Dimensions.spaceS),
        ],
        TextFormField(
          controller: widget.controller,
          focusNode: _internalFocusNode,
          obscureText: isPasswordField ? _isObscured : false,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onFieldSubmitted,
          onTap: widget.onTap,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          expands: widget.expands,
          textAlign: widget.textAlign,
          textAlignVertical: widget.textAlignVertical,
          autovalidateMode: widget.autovalidateMode,
          enableInteractiveSelection: widget.enableInteractiveSelection,
          cursorHeight: widget.cursorHeight,
          cursorColor: widget.cursorColor ?? AppColors.primary,
          style:
              widget.textStyle ??
              const TextStyle(fontSize: 16, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle:
                widget.hintStyle ??
                const TextStyle(color: AppColors.textHint, fontSize: 14),
            filled: widget.filled ?? true,
            fillColor:
                widget.fillColor ??
                (widget.enabled
                    ? _isFocused
                          ? AppColors.primary.withOpacity(0.02)
                          : AppColors.surface
                    : AppColors.gray200),
            contentPadding:
                widget.contentPadding ??
                const EdgeInsets.symmetric(
                  horizontal: Dimensions.spaceL,
                  vertical: Dimensions.spaceM,
                ),
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    color:
                        widget.prefixIconColor ??
                        (_isFocused ? AppColors.primary : AppColors.gray500),
                    size: Dimensions.iconSizeM,
                  )
                : null,
            prefixIconConstraints:
                widget.prefixIconConstraints ??
                const BoxConstraints(minWidth: 48, minHeight: 48),
            suffixIcon: _buildSuffixIcon(),
            suffixIconConstraints:
                widget.suffixIconConstraints ??
                const BoxConstraints(minWidth: 48, minHeight: 48),
            border: _getDefaultBorder(),
            enabledBorder:
                widget.enabledBorder ??
                _getDefaultBorder(
                  color: AppColors.border.withOpacity(0.5),
                  width: 1.5,
                ),
            focusedBorder:
                widget.focusedBorder ??
                _getDefaultBorder(color: AppColors.primary, width: 2),
            errorBorder:
                widget.errorBorder ??
                _getDefaultBorder(color: AppColors.error, width: 1.5),
            focusedErrorBorder:
                widget.focusedErrorBorder ??
                _getDefaultBorder(color: AppColors.error, width: 2),
            errorText: widget.errorText,
            counterText: widget.showCounter ? null : '',
            counterStyle: const TextStyle(height: 0, fontSize: 0),
          ),
        ),
      ],
    );
  }
}
