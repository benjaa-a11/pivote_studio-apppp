import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/theme/theme_provider.dart';
import 'package:pivote/features/profile/presentation/widgets/profile_design_system.dart';

class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = ProfilePalette.of(context);
    final themeProvider = context.watch<ThemeProvider>();

    return ProfileSubsectionScaffold(
      title: 'Apariencia',
      children: [
        AppAnimations.staggeredSlideIn(
          index: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ProfileSectionTitle('Tema', first: true),
              ProfileGroupCard(
                padding: const EdgeInsets.all(14),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _ThemePreviewOption(
                          label: 'Claro',
                          mode: ThemeMode.light,
                          selected: themeProvider.themeMode == ThemeMode.light,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            themeProvider.setThemeMode(ThemeMode.light);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ThemePreviewOption(
                          label: 'Oscuro',
                          mode: ThemeMode.dark,
                          selected: themeProvider.themeMode == ThemeMode.dark,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            themeProvider.setThemeMode(ThemeMode.dark);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ThemePreviewOption(
                          label: 'Sistema',
                          mode: ThemeMode.system,
                          selected: themeProvider.themeMode == ThemeMode.system,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            themeProvider.setThemeMode(ThemeMode.system);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        AppAnimations.staggeredSlideIn(
          index: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ProfileSectionTitle('Color de acento'),
              ProfileGroupCard(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      for (int i = 0;
                          i < ThemeProvider.accentSwatches.length;
                          i++) ...[
                        _AccentSwatchItem(
                          color: ThemeProvider.accentSwatches[i],
                          selected: themeProvider.accentIndex == i,
                          palette: palette,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            themeProvider.setAccentIndex(i);
                          },
                        ),
                        if (i < ThemeProvider.accentSwatches.length - 1)
                          const SizedBox(width: 14),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        AppAnimations.staggeredSlideIn(
          index: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ProfileSectionTitle('Texto'),
              ProfileGroupCard(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Pequeño',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: palette.muted,
                              ),
                            ),
                            Text(
                              'Grande',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: palette.muted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: palette.switchOn,
                            inactiveTrackColor: palette.switchOff,
                            thumbColor: palette.switchOn,
                            overlayColor:
                                palette.switchOn.withValues(alpha: 0.14),
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 9,
                            ),
                          ),
                          child: Slider(
                            min: 1,
                            max: 5,
                            divisions: 4,
                            value: themeProvider.textScaleStep.toDouble(),
                            onChanged: (val) {
                              HapticFeedback.selectionClick();
                              themeProvider.setTextScaleStep(val.round());
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  ProfileGroupRow(
                    title: 'Reducir animaciones',
                    subtitle: 'Menos movimiento en transiciones',
                    onTap: () => themeProvider
                        .setReduceAnimations(!themeProvider.reduceAnimations),
                    trailing: ProfileSwitch(
                      value: themeProvider.reduceAnimations,
                      onChanged: (val) =>
                          themeProvider.setReduceAnimations(val),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemePreviewOption extends StatelessWidget {
  final String label;
  final ThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  const _ThemePreviewOption({
    required this.label,
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = ProfilePalette.of(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 78,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? palette.text : palette.border,
                width: 2,
              ),
              color: mode == ThemeMode.light
                  ? Colors.white
                  : mode == ThemeMode.dark
                      ? const Color(0xFF1B1D22)
                      : null,
              gradient: mode == ThemeMode.system
                  ? const LinearGradient(
                      colors: [
                        Colors.white,
                        Colors.white,
                        Color(0xFF1B1D22),
                        Color(0xFF1B1D22),
                      ],
                      stops: [0.0, 0.5, 0.5, 1.0],
                    )
                  : null,
            ),
            child: Stack(
              children: [
                // Top skeleton bar (::before)
                Positioned(
                  left: 10,
                  right: 10,
                  top: 12,
                  height: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: mode == ThemeMode.dark
                          ? Colors.white.withValues(alpha: 0.20)
                          : Colors.black.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                // Bottom skeleton card (::after)
                Positioned(
                  left: 10,
                  top: 30,
                  height: 28,
                  width: 56,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: mode == ThemeMode.dark
                          ? Colors.white.withValues(alpha: 0.20)
                          : Colors.black.withValues(alpha: 0.10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? palette.text : palette.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccentSwatchItem extends StatelessWidget {
  final Color color;
  final bool selected;
  final ProfilePalette palette;
  final VoidCallback onTap;

  const _AccentSwatchItem({
    required this.color,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 42,
        height: 42,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? palette.text : Colors.transparent,
            width: 2,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: palette.card,
              width: 3,
            ),
          ),
        ),
      ),
    );
  }
}
