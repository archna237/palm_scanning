import 'package:flutter/material.dart';
import 'package:scanning_app/src/core/widgets/section_card.dart';
import 'package:scanning_app/src/features/compatibility/presentation/compatibility_screen.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionCard(
            title: 'Life Purpose',
            subtitle: 'Understand your core strengths and direction.',
            icon: Icons.explore,
          ),
          const SizedBox(height: 12),
          const SectionCard(
            title: 'Hidden Talent',
            subtitle: 'Reveal natural abilities based on palm features.',
            icon: Icons.lightbulb,
          ),
          const SizedBox(height: 12),
          const SectionCard(
            title: 'Prosperity',
            subtitle: 'Insights about growth, money and opportunities.',
            icon: Icons.savings,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CompatibilityScreen(),
                ),
              );
            },
            child: const Text('Check Compatibility'),
          ),
        ],
      ),
    );
  }
}
