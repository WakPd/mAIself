import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

class ScanFabButton extends StatelessWidget {
  const ScanFabButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => context.go("/scan"),
      icon: const Icon(Icons.camera_alt),
      label: const Text("Scan meal"),
    );
  }
}
