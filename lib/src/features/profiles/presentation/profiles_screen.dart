import 'package:flutter/material.dart';
import 'package:scanning_app/src/core/widgets/section_card.dart';

class ProfilesScreen extends StatelessWidget {
  const ProfilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Profiles')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SectionCard(
            title: 'You',
            subtitle: 'Dominant hand scan completed',
            icon: Icons.person,
          ),
          SizedBox(height: 12),
          SectionCard(
            title: 'Aarav',
            subtitle: 'Added for compatibility check',
            icon: Icons.person_outline,
          ),
          SizedBox(height: 12),
          SectionCard(
            title: 'Sara',
            subtitle: 'Last updated 2 days ago',
            icon: Icons.person_outline,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: const Text('Add Profile'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
