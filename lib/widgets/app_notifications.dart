import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppNotifications {
  static void showSuccess(BuildContext context, String message) {
    _showSnackBar(
      context,
      message,
      const Color(0xFF4CAF50), // Standard Success Green
      Icons.check_circle_rounded,
    );
  }

  static void showError(BuildContext context, String message) {
    _showSnackBar(
      context,
      message,
      const Color(0xFFE53935), // Standard Danger Red
      Icons.error_rounded,
    );
  }

  static void showWarning(BuildContext context, String message) {
    _showSnackBar(
      context,
      message,
      const Color(0xFFFFA000), // Standard Warning Amber
      Icons.warning_rounded,
    );
  }

  static void showInfo(BuildContext context, String message) {
    _showSnackBar(
      context,
      message,
      Theme.of(context).colorScheme.primary,
      Icons.info_rounded,
    );
  }

  static void _showSnackBar(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              // Styled Icon Container
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  // Subtle border to prevent "line" issues if any
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.ubuntu(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: color.withValues(alpha: 0.95),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 12,
        duration: const Duration(seconds: 4),
        // Smooth slide & fade animation
        animation: CurvedAnimation(
          parent: AnimationController(
            vsync: ScaffoldMessenger.of(context),
            duration: const Duration(milliseconds: 600),
          )..forward(),
          curve: Curves.easeOutBack,
        ),
      ),
    );
  }
}
