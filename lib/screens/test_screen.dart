import 'package:flutter/material.dart';

import '../core/helpers/throttled_scroll_mixin.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> with ThrottledScrollMixin {
  // Use a hardcoded path for demo

  // From ThrottledScrollMixin

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Performance Demo")),
      body: ListView.builder(
        controller: scrollController, // Attached to ThrottledScrollMixin
        itemCount: 50,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: CircleAvatar(child: Text("$index")),
              title: Text("Item $index"),
              subtitle: Text(
                index == 0
                    ? "Data: $index"
                    : "Scroll down to test throttling...",
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void onScroll() {
    // TODO: implement onScroll
  }
}
