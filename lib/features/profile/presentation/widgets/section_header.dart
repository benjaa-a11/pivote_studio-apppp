import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

/// Modern section header for profile groups
class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? color;
  final EdgeInsets? padding;

  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.color,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerColor = color ?? Theme.of(context).colorScheme.primary;

    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: headerColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: headerColor,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.syne(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[300] : Colors.grey[800],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    headerColor.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
