// DeeplinkScreen.dart
import 'package:flutter/material.dart';
import '../../../widgets/app_text.dart';

class DeeplinkScreen extends StatelessWidget {
  final Widget child;
  const DeeplinkScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SizedBox()),
        ); //add default screen here
      },
      child: child,
    );
  }
}

class DeepLinkNotifier extends StatelessWidget {
  final String message;
  const DeepLinkNotifier({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Txt(message)));
  }
}
