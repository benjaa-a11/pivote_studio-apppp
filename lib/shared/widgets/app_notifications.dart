import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppNotifications {
  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message,
      const Color(0xFF00C853), // Deep Android Green
      Icons.check_circle_outline_rounded,
    );
  }

  static void showError(BuildContext context, String message) {
    _show(
      context,
      message,
      const Color(0xFFD32F2F), // Deep Material Red
      Icons.error_outline_rounded,
    );
  }

  static void showWarning(BuildContext context, String message) {
    _show(
      context,
      message,
      const Color(0xFFFFA000), // Amber 700
      Icons.warning_amber_rounded,
    );
  }

  static void showInfo(BuildContext context, String message) {
    _show(
      context,
      message,
      Theme.of(context).primaryColor,
      Icons.info_outline_rounded,
    );
  }

  static void _show(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Stack(
          children: [
            // Glassmorphism background effect is simulated with opacity and blur is hard in SnackBar
            // So we use a high-quality container design
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: -2,
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      message,
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        letterSpacing: 0.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: EdgeInsets.zero, // Important to let Container handle padding
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
