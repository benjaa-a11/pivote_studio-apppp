import 'package:flutter/material.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/theme/app_colors.dart';
import 'package:pivote/core/theme/app_typography.dart';
import 'package:pivote/features/profile/presentation/screens/support_screen.dart';
import 'package:pivote/features/profile/presentation/widgets/profile_design_system.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  void _showLegalModal(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    final palette = ProfilePalette.of(context);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFont.primary(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  body,
                  style: AppFont.primary(
                    fontSize: 14,
                    color: palette.muted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                ProfileActionButton(
                  label: 'Entendido',
                  onTap: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ProfilePalette.of(context);

    return ProfileSubsectionScaffold(
      title: 'Acerca de',
      children: [
        AppAnimations.staggeredSlideIn(
          index: 0,
          child: Padding(
            padding: const EdgeInsets.only(top: 18, bottom: 18),
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.accent,
                        AppColors.accentStrong,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.35),
                        blurRadius: 24,
                        spreadRadius: -8,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'P',
                    style: AppFont.primary(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink0,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Pivote',
                  style: AppFont.primary(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Versión 1.0.0 (build 1)',
                  style: AppFont.primary(
                    fontSize: 14.5,
                    color: palette.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
        AppAnimations.staggeredSlideIn(
          index: 1,
          child: ProfileGroupCard(
            children: [
              ProfileGroupRow(
                title: 'Términos y condiciones',
                showChevron: true,
                onTap: () => _showLegalModal(
                  context,
                  title: 'Términos y condiciones',
                  body:
                      'El uso de Pivote Studio está sujeto a las normas de uso personal y no comercial. Las señales en vivo, eventos deportivos y emisoras pertenecen a sus respectivos titulares.',
                ),
              ),
              ProfileGroupRow(
                title: 'Política de privacidad',
                showChevron: true,
                onTap: () => _showLegalModal(
                  context,
                  title: 'Política de privacidad',
                  body:
                      'Pivote Studio protege tus credenciales mediante cifrado de extremo a extremo. No vendemos ni compartimos tus datos personales con terceros.',
                ),
              ),
              ProfileGroupRow(
                title: 'Licencias de código abierto',
                showChevron: true,
                onTap: () {
                  showLicensePage(
                    context: context,
                    applicationName: 'Pivote',
                    applicationVersion: '1.0.0 (build 1)',
                    applicationLegalese: '© 2026 Pivote Studio',
                  );
                },
              ),
              ProfileGroupRow(
                title: 'Ayuda y soporte',
                showChevron: true,
                onTap: () {
                  Navigator.push(
                    context,
                    AppAnimations.createRoute(const SupportScreen()),
                  );
                },
              ),
            ],
          ),
        ),
        AppAnimations.staggeredSlideIn(
          index: 2,
          child: Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Text(
              '© 2026 Pivote Studio',
              textAlign: TextAlign.center,
              style: AppFont.primary(
                fontSize: 13,
                color: palette.muted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
