import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';

import 'package:scanning_app/src/core/palm_reading/palm_reading_result.dart';

/// Reads [GEMINI_API_KEY] from `--dart-define=GEMINI_API_KEY=...` at compile time.
/// Without a key, [analyzePalmImage] returns a deterministic demo reading so the
/// flow still works for UI review.
class PalmReadingService {
  PalmReadingService._();

  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _modelName = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-2.0-flash',
  );

  static final Schema _readingSchema = Schema.object(
    properties: {
      'overview': Schema.string(
        description:
            '2–4 sentences: warm greeting and what you notice first on the palm, entertainment only.',
      ),
      'love': Schema.string(
        description:
            'Heart line and relationship themes in plain, palm-reader style (3–5 sentences).',
      ),
      'career': Schema.string(
        description:
            'Head line, fate line if visible, work and ambition (3–5 sentences).',
      ),
      'health': Schema.string(
        description:
            'Vitality and balance as symbolic palmistry only, not medical advice (2–4 sentences).',
      ),
      'destiny': Schema.string(
        description:
            'Life path and timing as a reader would phrase it (3–5 sentences).',
      ),
    },
    requiredProperties: ['love', 'career', 'health', 'destiny', 'overview'],
  );

  static Future<PalmReadingResult> analyzePalmImage({
    required Uint8List imageBytes,
    required String mimeType,
  }) async {
    if (_apiKey.isEmpty) {
      return _demoReading(_seedFromBytes(imageBytes));
    }

    final model = GenerativeModel(
      model: _modelName,
      apiKey: _apiKey,
      systemInstruction: Content.system(
        'You are an experienced palm reader giving a single entertainment reading. '
        'Study the palm photo: mention major lines only if you can reasonably see them; '
        'if the image is unclear, say so gently and still offer a cohesive symbolic reading. '
        'Tone: warm, specific, like a thoughtful reader—not generic horoscope blurbs. '
        'Never claim supernatural certainty; this is for fun and reflection.',
      ),
      generationConfig: GenerationConfig(
        temperature: 0.75,
        maxOutputTokens: 1200,
        responseMimeType: 'application/json',
        responseSchema: _readingSchema,
      ),
    );

    final prompt = Content.multi([
      TextPart(
        'Give this client their palm reading as JSON matching the schema. '
        'Base details on what is visible in the image.',
      ),
      DataPart(mimeType, imageBytes),
    ]);

    try {
      final response = await model.generateContent([prompt]);
      final text = response.text?.trim();
      if (text == null || text.isEmpty) {
        throw PalmReadingException('No response from the reader. Try again in a moment.');
      }

      final decoded = jsonDecode(text);
      if (decoded is! Map) {
        throw PalmReadingException('Could not parse the reading. Please scan again.');
      }
      final map = Map<String, dynamic>.from(decoded);

      final result = PalmReadingResult.fromJson(map);
      if (result.hasEmptySections) {
        throw PalmReadingException('The reading came back empty. Try another photo.');
      }
      return result;
    } on InvalidApiKey catch (e) {
      throw PalmReadingException('Invalid Gemini API key: ${e.message}');
    } on UnsupportedUserLocation catch (_) {
      throw PalmReadingException(
        'Gemini is not available in your region for this API setup.',
      );
    } on GenerativeAIException catch (e) {
      throw PalmReadingException(e.message);
    }
  }

  static int _seedFromBytes(Uint8List b) {
    var h = 0;
    final n = b.length < 1200 ? b.length : 1200;
    for (var i = 0; i < n; i++) {
      h = (h * 31 + b[i]) & 0x7fffffff;
    }
    return h == 0 ? 1 : h;
  }

  static PalmReadingResult _demoReading(int seed) {
    final r = Random(seed);
    String pick(List<String> xs) => xs[r.nextInt(xs.length)];

    final love = [
      '${pick(_loveOpeners)} ${pick(_loveMiddles)} ${pick(_loveClosers)}',
      '${pick(_loveOpeners)} ${pick(_loveClosers)}',
    ][r.nextInt(2)];

    final career = [
      '${pick(_careerOpeners)} ${pick(_careerMiddles)} ${pick(_careerClosers)}',
      '${pick(_careerOpeners)} ${pick(_careerClosers)}',
    ][r.nextInt(2)];

    final health = [
      '${pick(_healthOpeners)} ${pick(_healthMiddles)} ${pick(_healthClosers)}',
    ][0];

    final destiny = [
      '${pick(_destinyOpeners)} ${pick(_destinyMiddles)} ${pick(_destinyClosers)}',
    ][0];

    final overview =
        'This is a demo reading (no AI key configured). Each scan picks different symbolic lines. '
        'For a real vision reading from your photo, run or build the app with '
        '--dart-define=GEMINI_API_KEY=your_key from Google AI Studio.';

    return PalmReadingResult(
      love: love,
      career: career,
      health: health,
      destiny: destiny,
      overview: overview,
      isAiPowered: false,
    );
  }
}

class PalmReadingException implements Exception {
  PalmReadingException(this.message);
  final String message;

  @override
  String toString() => message;
}

const _loveOpeners = [
  'The heart line here speaks of loyalty once trust is earned.',
  'Emotional currents run deep; you feel first and sort the story later.',
  'Connections matter to you more than appearances—your palm shows a generous attachment style.',
];

const _loveMiddles = [
  'Partnerships grow when you name what you need instead of hinting.',
  'A chapter of clearer boundaries will actually soften old resentments.',
  'Romance favors slow warmth over sudden fireworks.',
];

const _loveClosers = [
  'Let curiosity replace suspicion when someone shows up consistently.',
  'The next meaningful bond rewards honesty spoken kindly.',
];

const _careerOpeners = [
  'The head line favors roles where you connect ideas others treat as separate.',
  'You are built for craft plus communication—teaching, design, or guiding a team.',
  'Work satisfaction rises when your week has one stretch project, not only maintenance.',
];

const _careerMiddles = [
  'A mentor-shaped opportunity may arrive disguised as extra responsibility.',
  'Your best leverage is documentation: what you clarify becomes your reputation.',
];

const _careerClosers = [
  'Say yes to learning that pays forward within two seasons.',
  'Protect focus time; your palm shows scattered brilliance when concentration holds.',
];

const _healthOpeners = [
  'Vitality symbols suggest rhythm matters more than intensity—steady sleep wins.',
  'Your hand hints at strong recovery when you alternate effort with true rest.',
];

const _healthMiddles = [
  'Treat energy like a budget: spend it on what aligns with your values.',
];

const _healthClosers = [
  'This is symbolic palmistry only, not medical advice.',
];

const _destinyOpeners = [
  'The life line’s curve suggests reinvention, not a single fixed path.',
  'A visible shift in priorities marks the coming growth phase more than geography.',
];

const _destinyMiddles = [
  'Destiny here looks co-authored: your choices echo louder than circumstance.',
  'What you forgive (including yourself) opens space for a cleaner next chapter.',
];

const _destinyClosers = [
  'Trust small consistent steps; they compound into a new storyline.',
  'Keep one private ritual—music, walk, journal—to anchor decisions.',
];
