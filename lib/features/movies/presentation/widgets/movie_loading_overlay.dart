import 'package:flutter/material.dart';
import 'package:pivote/shared/widgets/common/pivote_loader.dart';

class MovieLoadingOverlay extends StatelessWidget {
  final int retryAttempt;

  const MovieLoadingOverlay({
    super.key,
    this.retryAttempt = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: PivoteLoader(
          size: 45,
          strokeWidth: 4.5,
        ),
      ),
    );
  }
}
