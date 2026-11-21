import 'package:flutter/material.dart';
import 'package:pivote/features/auth/data/models/user_model.dart';
import 'package:pivote/features/auth/presentation/providers/user_provider.dart';
import 'package:pivote/features/auth/presentation/screens/account_status_screen.dart';

/// Envoltorio de compatibilidad que delega a [AccountStatusScreen].
class SuspendedScreen extends StatelessWidget {
  const SuspendedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AccountStatusScreen(
      info: AccountBlockInfo(reason: AccountBlockReason.revoked),
    );
  }
}
