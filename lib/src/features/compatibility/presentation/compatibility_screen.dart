import 'package:flutter/material.dart';

class CompatibilityScreen extends StatefulWidget {
  const CompatibilityScreen({super.key});

  @override
  State<CompatibilityScreen> createState() => _CompatibilityScreenState();
}

class _CompatibilityScreenState extends State<CompatibilityScreen> {
  final _nameController = TextEditingController();
  final _zodiacController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _zodiacController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compatibility')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Partner Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _zodiacController,
              decoration: const InputDecoration(labelText: 'Partner Zodiac'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Compatibility Result'),
                    content: Text(
                      '${_nameController.text.isEmpty ? 'Partner' : _nameController.text} '
                      'has a 78% affinity based on profile and hand pattern.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Analyze Compatibility'),
            ),
          ],
        ),
      ),
    );
  }
}
