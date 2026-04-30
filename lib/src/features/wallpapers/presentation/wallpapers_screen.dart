import 'package:flutter/material.dart';

class WallpapersScreen extends StatelessWidget {
  const WallpapersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mystic Wallpapers')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.62,
        ),
        itemBuilder: (_, index) => ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            color: Colors.deepPurple.withValues(alpha: 0.1 * ((index % 5) + 3)),
            child: const Center(
              child: Icon(Icons.auto_awesome, size: 40),
            ),
          ),
        ),
      ),
    );
  }
}
