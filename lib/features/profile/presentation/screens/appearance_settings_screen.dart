import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/services/wakelock_service.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/core/theme/theme_provider.dart';
import 'package:pivote/features/profile/presentation/widgets/profile_design_system.dart';
import 'package:pivote/shared/widgets/common/apple_pressable.dart';

class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final wakelockService = context.watch<WakelockService>();
    final accent = AppTheme.accent(context);
    final scalePct = (themeProvider.textScaleFactor * 100).round();

    return ProfileSubsectionScaffold(
      title: 'Apariencia',
      subtitle: 'Tema visual y confort de lectura',
      children: [
        AppAnimations.staggeredSlideIn(
          index: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ProfileSectionTitle('Tema de la interfaz', first: true),
              ProfileGroupCard(
                padding: const EdgeInsets.all(14),
                highlighted: true,
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
              const ProfileSectionTitle('Texto y pantalla'),
              ProfileGroupCard(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tamaño de texto',
                              style: AppFont.primary(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary(context),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accentDim(context),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                '$scalePct%',
                                style: AppFont.mono(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'A',
                              style: AppFont.primary(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textTertiary(context),
                              ),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: accent,
                                  inactiveTrackColor: AppTheme.surface4(context),
                                  thumbColor: accent,
                                  overlayColor: accent.withValues(alpha: 0.14),
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 8.5,
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
                            ),
                            Text(
                              'A',
                              style: AppFont.primary(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ProfileGroupRow(
                    title: 'Reducir animaciones',
                    subtitle: 'Menos movimiento en transiciones y anillos',
                    onTap: () => themeProvider
                        .setReduceAnimations(!themeProvider.reduceAnimations),
                    trailing: ProfileSwitch(
                      value: themeProvider.reduceAnimations,
                      onChanged: (val) =>
                          themeProvider.setReduceAnimations(val),
                    ),
                  ),
                  ProfileGroupRow(
                    title: 'Pantalla siempre activa',
                    subtitle: 'Evita que la pantalla se apague en la app',
                    onTap: () => wakelockService.toggle(),
                    trailing: ProfileSwitch(
                      value: wakelockService.keepScreenOn,
                      onChanged: (val) =>
                          wakelockService.setKeepScreenOn(val),
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
    final accent = AppTheme.accent(context);
    final onAccent = AppTheme.onAccent(context);

    return ApplePressable(
      scaleDownFactor: 0.96,
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: AppMotion.fast,
            height: 82,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: selected ? accent : AppTheme.border(context),
                width: selected ? 2 : 1,
              ),
              color: mode == ThemeMode.light
                  ? AppColors.lightBg
                  : mode == ThemeMode.dark
                      ? AppColors.darkBg
                      : null,
              gradient: mode == ThemeMode.system
                  ? const LinearGradient(
                      colors: [
                        AppColors.lightBg,
                        AppColors.lightBg,
                        AppColors.darkBg,
                        AppColors.darkBg,
                      ],
                      stops: [0.0, 0.5, 0.5, 1.0],
                    )
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Mini difuminación radial de acento en la esquina superior derecha
                Positioned(
                  top: -18,
                  right: -18,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          (mode == ThemeMode.light
                                  ? AppColors.lightAccent
                                  : AppColors.darkAccent)
                              .withValues(alpha: 0.28),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Mini barras de tarjeta simulada
                Positioned(
                  left: 10,
                  right: 10,
                  top: 14,
                  height: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: mode == ThemeMode.dark
                          ? AppColors.darkBg3
                          : AppColors.lightBorder2,
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  top: 30,
                  height: 30,
                  right: 26,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: mode == ThemeMode.dark
                          ? AppColors.darkBg2
                          : AppColors.lightBg1,
                      border: Border.all(
                        color: mode == ThemeMode.dark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                  ),
                ),
                if (selected)
                  Positioned(
                    right: 7,
                    bottom: 7,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 13,
                        color: onAccent,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppFont.primary(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected
                  ? AppTheme.textPrimary(context)
                  : AppTheme.textTertiary(context),
            ),
          ),
        ],
      ),
    );
  }
}
