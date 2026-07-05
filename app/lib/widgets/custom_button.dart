import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum CustomButtonType { primary, secondary, accent }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final CustomButtonType type;
  final bool isLoading;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = CustomButtonType.primary,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    // Determine colors based on type
    final Color backgroundColor;
    final Color textColor;
    
    switch (type) {
      case CustomButtonType.primary:
        backgroundColor = AppColors.primary;
        textColor = Colors.white;
        break;
      case CustomButtonType.secondary:
        backgroundColor = AppColors.secondary;
        textColor = Colors.white;
        break;
      case CustomButtonType.accent:
        backgroundColor = AppColors.accent;
        textColor = AppColors.primary; // Contrast with teal
        break;
    }

    final isButtonEnabled = onPressed != null && !isLoading;
    
    return SizedBox(
      width: double.infinity,
      height: 56, // Modern premium size
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          disabledBackgroundColor: isButtonEnabled ? null : backgroundColor.withOpacity(0.5),
          disabledForegroundColor: isButtonEnabled ? null : textColor.withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        onPressed: isButtonEnabled ? onPressed : null,
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
