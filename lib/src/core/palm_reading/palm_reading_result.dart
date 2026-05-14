class PalmReadingResult {
  const PalmReadingResult({
    required this.love,
    required this.career,
    required this.health,
    required this.destiny,
    this.overview,
    this.isAiPowered = false,
  });

  final String love;
  final String career;
  final String health;
  final String destiny;
  final String? overview;
  final bool isAiPowered;

  factory PalmReadingResult.fromJson(Map<String, dynamic> json) {
    String s(String key) {
      final v = json[key];
      if (v is String) return v.trim();
      if (v != null) return v.toString().trim();
      return '';
    }
    return PalmReadingResult(
      love: s('love'),
      career: s('career'),
      health: s('health'),
      destiny: s('destiny'),
      overview: () {
        final o = s('overview');
        return o.isEmpty ? null : o;
      }(),
      isAiPowered: true,
    );
  }

  bool get hasEmptySections =>
      love.isEmpty && career.isEmpty && health.isEmpty && destiny.isEmpty;
}
