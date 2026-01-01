import 'package:flutter/material.dart';
import '../network/api_services/api_client.dart';
import '../network/notifiers/swr_mixin.dart';
import '../network/notifiers/ui_builder.dart';
import '../network/api_services/state_response.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> with SwrMixin {
  // Use a hardcoded path for demo
  final String _demoPath = '/posts/1';
  late StateResponse<dynamic> _state;
  final ApiClient _api = ApiClient();

  @override
  void initState() {
    super.initState();
    _state = StateResponse.loading();
    _fetchData();

    // 1. Listen for SWR updates!
    listenToSwr(_demoPath, () {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✨ Fresh data arrived from background!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
      _fetchData(); // Reload from cache (which is now fresh)
    });
  }

  Future<void> _fetchData() async {
    // 2. Fetch using SWR (Default)
    // First call: Returns null (if empty) -> waiting for network
    // Second call: Returns Cache immediately -> waiting for background refresh
    final result = await _api.get(
      _demoPath,
      // For demo purposes, we can toggle these to see different behaviors
      staleWhileRevalidate: true,
      sessionStale:
          false, // Set false so we can see updates every time we enter
    );

    result.when(
      success: (data) {
        if (mounted) {
          setState(() {
            _state = StateResponse.success(data.data);
          });
        }
      },
      failure: (error) {
        if (mounted) {
          setState(() {
            _state = StateResponse.failure(error);
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SWR Demo")),
      body: UiBuilder(
        response: _state,
        onSuccess: (data) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 64),
                const SizedBox(height: 16),
                Text(
                  "Data: $data",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _state = StateResponse.loading();
                    });
                    _fetchData();
                  },
                  child: const Text("Manual Reload"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
