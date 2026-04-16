import "package:flutter_riverpod/flutter_riverpod.dart";

final dashboardProvider = StateProvider<Map<String, int>>((ref) {
  return <String, int>{"energy": 50, "sleep": 50, "concentration": 50};
});
