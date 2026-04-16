import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan")),
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.go("/result"),
          child: const Text("Analyze meal"),
        ),
      ),
    );
  }
}
