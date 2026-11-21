import 'package:flutter/material.dart';
import 'package:pivote/core/theme/app_theme.dart';
import 'package:pivote/core/theme/app_tokens.dart';
import 'package:pivote/shared/widgets/common/apple_pressable.dart';
import 'package:pivote/shared/widgets/common/pivote_surfaces.dart';

class NoInternetScreen extends StatelessWidget {
  final VoidCallback onRetry;

  const NoInternetScreen({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.accent(context);
    final onAccent = AppTheme.onAccent(context);

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: PivoteAmbientBackdrop(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: PivoteDiffusedCard(
                  borderRadius: AppRadius.hero,
                  glowColor: accent,
                  glowAlignment: const Alignment(0.0, -0.9),
                  glowOpacity: 1.35,
                  highlighted: true,
                  padding: const EdgeInsets.fromLTRB(26, 32, 26, 26),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          color: AppTheme.accentDim(context),
                          borderRadius: BorderRadius.circular(AppRadius.hero),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.34),
                            width: 1.2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.wifi_off_rounded,
                          size: 36,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Sin conexión',
                        textAlign: TextAlign.center,
                        style: AppFont.primary(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary(context),
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No detectamos acceso a internet. Comprobá tu Wi-Fi o datos móviles e intentá nuevamente.',
                        textAlign: TextAlign.center,
                        style: AppFont.primary(
                          fontSize: 13.8,
                          height: 1.5,
                          color: AppTheme.textSecondary(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 26),
                      ApplePressable(
                        scaleDownFactor: 0.97,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        onTap: onRetry,
                        child: Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            boxShadow: AppShadows.glow(accent, alpha: 0.25),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.refresh_rounded,
                                size: 19,
                                color: onAccent,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Reintentar',
                                style: AppFont.primary(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: onAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
