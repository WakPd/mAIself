import "package:flutter/material.dart";

import "core/config/router.dart";
import "core/theme/app_theme.dart";

class MaiselfApp extends StatelessWidget {
  const MaiselfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "mAIself",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
