import 'package:flutter/material.dart';
import '../../../core/config/provider_routes.dart';
import 'package:provider/provider.dart';
import '../../../app.dart';
import '../../../bootstrap.dart';

void main() async {
  await bootstrap();
  final width =
      WidgetsBinding
          .instance
          .platformDispatcher
          .views
          .first
          .physicalSize
          .width /
      WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;

  final bool isPhone = width <= 450; //pass figma phone width
  final bool isSmallPhone = width <= 360; //pass figma small phone width
  final app = MyApp(enableScale: isPhone || isSmallPhone);

  runApp(
    ProviderRoutes.listOfProviders.isEmpty
        ? app
        : MultiProvider(providers: ProviderRoutes.listOfProviders, child: app),
  );
}
