import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/features/profile/presentation/screens/support_screen.dart';
import 'package:pivote/features/profile/presentation/widgets/profile_design_system.dart';
import 'package:pivote/shared/widgets/common/app_dialogs.dart';
import 'package:pivote/shared/widgets/common/pivote_surfaces.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  void _showLegalModal(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    AppDialogs.showModal<void>(
      context: context,
      child: Builder(
        builder: (ctx) => SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PivoteSheetHeader(
                  title: title,
                  icon: Icons.description_outlined,
                ),
                const SizedBox(height: 14),
                Text(
                  body,
                  style: AppFont.primary(
                    fontSize: 13.8,
                    color: AppTheme.textSecondary(ctx),
                    height: 1.52,
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.accent(context);

    return ProfileSubsectionScaffold(
      title: 'Acerca de',
      children: [
        AppAnimations.staggeredSlideIn(
          index: 0,
          child: PivoteDiffusedCard(
            borderRadius: AppRadius.hero,
            glowColor: accent,
            glowAlignment: const Alignment(0.0, -0.8),
            glowOpacity: 1.35,
            highlighted: true,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface2(context),
                    borderRadius: BorderRadius.circular(AppRadius.hero),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.36),
                    ),
                  ),
                  child: SvgPicture.asset(
                    'assets/logo.svg',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Pivote Studio',
                  style: AppFont.primary(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.45,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentDim(context),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    'v1.0.0 · build 1',
                    style: AppFont.mono(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        AppAnimations.staggeredSlideIn(
          index: 1,
          child: ProfileGroupCard(
            children: [
              ProfileGroupRow(
                leading: const ProfileSettingIconBox(
                  icon: Icons.gavel_rounded,
                ),
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
                leading: const ProfileSettingIconBox(
                  icon: Icons.privacy_tip_outlined,
                ),
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
                leading: const ProfileSettingIconBox(
                  icon: Icons.code_rounded,
                ),
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
                leading: const ProfileSettingIconBox(
                  icon: Icons.support_agent_rounded,
                  highlight: true,
                ),
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
            padding: const EdgeInsets.only(top: 20),
            child: Text(
              '© 2026 Pivote Studio',
              textAlign: TextAlign.center,
              style: AppFont.primary(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textTertiary(context),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
