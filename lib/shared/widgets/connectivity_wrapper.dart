import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pivote/shared/screens/no_internet_screen.dart';

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectivityResult>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        final result = snapshot.data;

        // While we don't have the first result, we check it manually
        if (snapshot.connectionState == ConnectionState.waiting) {
          return FutureBuilder<ConnectivityResult>(
            future: Connectivity().checkConnectivity(),
            builder: (context, initialSnapshot) {
              if (!initialSnapshot.hasData) {
                return const Scaffold(body: SizedBox.shrink());
              }
              return _buildContent(context, initialSnapshot.data!);
            },
          );
        }

        return _buildContent(context, result ?? ConnectivityResult.none);
      },
    );
  }

  Widget _buildContent(BuildContext context, ConnectivityResult result) {
    final isOffline = result == ConnectivityResult.none;

    if (isOffline) {
      return NoInternetScreen(
        onRetry: () async {
          await Connectivity().checkConnectivity();
          // The stream will notify us if it changes
        },
      );
    }

    return widget.child;
  }
}
