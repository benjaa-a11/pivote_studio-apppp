import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pivote/core/animations/app_animations.dart';
import 'package:pivote/features/profile/presentation/screens/diagnostics_screen.dart';
import 'package:pivote/features/profile/presentation/screens/storage_manager_screen.dart';
import 'package:pivote/features/profile/presentation/widgets/profile_design_system.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  Future<void> _openUrl(String value) async {
    final uri = Uri.parse(value);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileSubsectionScaffold(
      title: 'Ayuda y soporte',
      children: [
        AppAnimations.staggeredSlideIn(
          index: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ProfileSectionTitle('Herramientas rápidas', first: true),
              ProfileGroupCard(
                children: [
                  ProfileGroupRow(
                    title: 'Diagnóstico de red',
                    subtitle: 'Comprobar velocidad, ping y calidad sugerida',
                    showChevron: true,
                    onTap: () => Navigator.push(
                      context,
                      AppAnimations.createRoute(const DiagnosticsScreen()),
                    ),
                  ),
                  ProfileGroupRow(
                    title: 'Gestionar almacenamiento',
                    subtitle: 'Liberar caché para optimizar la reproducción',
                    showChevron: true,
                    onTap: () => Navigator.push(
                      context,
                      AppAnimations.createRoute(const StorageManagerScreen()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        AppAnimations.staggeredSlideIn(
          index: 1,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileSectionTitle('Preguntas frecuentes'),
              ProfileGroupCard(
                children: [
                  ProfileGroupRow(
                    title: '¿Cómo guardo favoritos?',
                    subtitle:
                        'Tocá el ícono de corazón en cualquier canal o radio para sincronizarlo en tu cuenta.',
                  ),
                  ProfileGroupRow(
                    title: '¿Por qué hay pausas o buffering?',
                    subtitle:
                        'Revisá tu conexión Wi-Fi con el diagnóstico de red o limpiá la caché temporal.',
                  ),
                  ProfileGroupRow(
                    title: '¿Cómo cambio el tema visual?',
                    subtitle:
                        'Desde Perfil > Apariencia podés elegir entre Claro, Oscuro o Sistema y personalizar el color de acento.',
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
              const ProfileSectionTitle('Contacto directo'),
              ProfileGroupCard(
                children: [
                  ProfileGroupRow(
                    title: 'Correo de soporte',
                    valueText: 'soporte@pivote.com',
                    showChevron: true,
                    onTap: () => _openUrl('mailto:soporte@pivote.com'),
                  ),
                  ProfileGroupRow(
                    title: 'Telegram oficial',
                    valueText: '@pivote_support',
                    showChevron: true,
                    onTap: () => _openUrl('https://t.me/pivote_support'),
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
