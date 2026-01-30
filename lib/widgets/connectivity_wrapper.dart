import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../screens/no_internet_screen.dart';

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  late Future<ConnectivityResult> _initialConnectivity;

  @override
  void initState() {
    super.initState();
    // Check initial connectivity state immediately
    _initialConnectivity = Connectivity().checkConnectivity();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ConnectivityResult>(
      future: _initialConnectivity,
      builder: (context, initialSnapshot) {
        // Show loading while checking initial connection
        if (!initialSnapshot.hasData) {
          return Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        }

        // Once we have initial state, listen to changes
        return StreamBuilder<ConnectivityResult>(
          stream: Connectivity().onConnectivityChanged,
          initialData: initialSnapshot.data,
          builder: (context, streamSnapshot) {
            final result = streamSnapshot.data;
            final isOffline = result == ConnectivityResult.none;

            if (isOffline) {
              return NoInternetScreen(
                onRetry: () async {
                  // Force a refresh by checking connectivity
                  final newResult = await Connectivity().checkConnectivity();
                  if (newResult != ConnectivityResult.none) {
                    // Trigger rebuild by updating state
                    setState(() {
                      _initialConnectivity = Future.value(newResult);
                    });
                  }
                },
              );
            }

            return widget.child;
          },
        );
      },
    );
  }
}
