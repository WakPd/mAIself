import "package:flutter/material.dart";

import "../widgets/avatar_widget.dart";
import "../widgets/scan_fab_button.dart";

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: const Center(child: AvatarWidget()),
      floatingActionButton: const ScanFabButton(),
    );
  }
}
