import 'package:flutter/material.dart';

class Helper {
  static String capitalizeFirstLetter(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }

  static String getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return "UK";
    final parts = name
        .trim()
        .toUpperCase()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1);
    }
    return parts[0][0] + parts[1][0];
  }
}

class ValueListenableBuilder2<A, B> extends StatelessWidget {
  final ValueNotifier<A> first;
  final ValueNotifier<B> second;
  final Widget Function(BuildContext, A, B, Widget?) builder;

  const ValueListenableBuilder2({
    required this.first,
    required this.second,
    required this.builder,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (context, aValue, _) {
        return ValueListenableBuilder<B>(
          valueListenable: second,
          builder: (context, bValue, _) {
            return builder(context, aValue, bValue, null);
          },
        );
      },
    );
  }
}

class ValueListenableBuilder3<A, B, C> extends StatelessWidget {
  final ValueNotifier<A> first;
  final ValueNotifier<B> second;
  final ValueNotifier<C> third;

  final Widget Function(BuildContext context, A a, B b, C c, Widget? child)
  builder;
  final Widget? child;

  const ValueListenableBuilder3({
    super.key,
    required this.first,
    required this.second,
    required this.third,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (context, aValue, _) {
        return ValueListenableBuilder<B>(
          valueListenable: second,
          builder: (context, bValue, _) {
            return ValueListenableBuilder<C>(
              valueListenable: third,
              builder: (context, cValue, _) {
                return builder(context, aValue, bValue, cValue, child);
              },
            );
          },
        );
      },
    );
  }
}
