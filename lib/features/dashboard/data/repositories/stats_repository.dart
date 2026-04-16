class StatsRepository {
  Future<Map<String, int>> getStats() async {
    return <String, int>{"energy": 50, "sleep": 50, "concentration": 50};
  }
}
