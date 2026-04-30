import 'package:flutter/material.dart';
import 'package:scanning_app/src/core/widgets/section_card.dart';

class ReadingResultScreen extends StatelessWidget {
  const ReadingResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Reading')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SectionCard(
            title: 'Love',
            subtitle: 'Strong emotional depth and loyal heart energy.',
            icon: Icons.favorite,
          ),
          SizedBox(height: 12),
          SectionCard(
            title: 'Career',
            subtitle: 'You perform best in creative and analytical roles.',
            icon: Icons.work,
          ),
          SizedBox(height: 12),
          SectionCard(
            title: 'Health & Vitality',
            subtitle: 'Good recovery strength with a need for better rest.',
            icon: Icons.health_and_safety,
          ),
          SizedBox(height: 12),
          SectionCard(
            title: 'Destiny',
            subtitle: 'A major life shift appears in your next growth phase.',
            icon: Icons.auto_graph,
          ),
        ],
      ),
    );
  }
}
