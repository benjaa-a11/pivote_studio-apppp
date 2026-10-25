import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pivote/shared/screens/no_internet_screen.dart';

/// Envuelve la aplicación y muestra [NoInternetScreen] cuando no hay
/// conectividad. Compatible con connectivity_plus 5.0.2 (emite ConnectivityResult).
class ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectivityResult>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        // Mientras espera el primer evento del stream, comprobación inicial
        if (snapshot.connectionState == ConnectionState.waiting) {
          return FutureBuilder<ConnectivityResult>(
            future: Connectivity().checkConnectivity(),
            builder: (context, initialSnapshot) {
              if (!initialSnapshot.hasData) {
                // Optimista: muestra la app mientras se espera el resultado
                return widget.child;
              }
              return _buildContent(context, initialSnapshot.data!);
            },
          );
        }

        return _buildContent(
          context,
          snapshot.data ?? ConnectivityResult.none,
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, ConnectivityResult result) {
    if (result == ConnectivityResult.none) {
      return NoInternetScreen(
        onRetry: () async {
          // El stream notificará automáticamente cuando cambie el estado
          await Connectivity().checkConnectivity();
        },
      );
    }

    return widget.child;
  }
}
