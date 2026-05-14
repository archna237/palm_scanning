import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:scanning_app/src/core/palm_reading/palm_reading_result.dart';
import 'package:scanning_app/src/core/palm_reading/palm_reading_service.dart';
import 'package:scanning_app/src/core/widgets/section_card.dart';

class ReadingResultScreen extends StatefulWidget {
  const ReadingResultScreen({required this.imagePath, super.key});

  final String imagePath;

  @override
  State<ReadingResultScreen> createState() => _ReadingResultScreenState();
}

class _ReadingResultScreenState extends State<ReadingResultScreen> {
  Uint8List? _imageBytes;
  PalmReadingResult? _reading;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _runReading();
  }

  String _mimeTypeForPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _runReading() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bytes = await XFile(widget.imagePath).readAsBytes();
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
      });
      final result = await PalmReadingService.analyzePalmImage(
        imageBytes: bytes,
        mimeType: _mimeTypeForPath(widget.imagePath),
      );
      if (!mounted) return;
      setState(() {
        _reading = result;
        _loading = false;
        _error = null;
      });
    } on PalmReadingException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Reading')),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'The reader is studying your palm lines…',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off, size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(
                _error is PalmReadingException
                    ? (_error! as PalmReadingException).message
                    : 'Something went wrong. Check your connection and API key, then try again.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _runReading,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    final reading = _reading;
    if (reading == null) {
      return const SizedBox.shrink();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_imageBytes != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.memory(
                _imageBytes!,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (!reading.isAiPowered)
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Demo mode: add a Gemini API key for a real vision reading from your photo. '
                'Flutter run example:\nflutter run --dart-define=GEMINI_API_KEY=YOUR_KEY',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        if (!reading.isAiPowered) const SizedBox(height: 12),
        if (reading.overview != null && reading.overview!.isNotEmpty) ...[
          SectionCard(
            title: "Reader's note",
            subtitle: reading.overview!,
            icon: Icons.auto_awesome,
          ),
          const SizedBox(height: 12),
        ],
        SectionCard(
          title: 'Love',
          subtitle: reading.love.isNotEmpty ? reading.love : 'Open your heart line with patience.',
          icon: Icons.favorite,
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Career',
          subtitle: reading.career.isNotEmpty ? reading.career : 'Your path rewards steady skill-building.',
          icon: Icons.work,
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Health & vitality',
          subtitle: reading.health.isNotEmpty ? reading.health : 'Balance effort with rest as a ritual.',
          icon: Icons.health_and_safety,
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Destiny',
          subtitle: reading.destiny.isNotEmpty ? reading.destiny : 'Small loyal choices rewrite the larger story.',
          icon: Icons.auto_graph,
        ),
        const SizedBox(height: 24),
        Text(
          'For entertainment only.',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
