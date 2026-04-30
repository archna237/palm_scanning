import 'package:flutter/material.dart';

class ArticlesScreen extends StatelessWidget {
  const ArticlesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const articles = [
      'How to read the life line accurately',
      'Difference between dominant and non-dominant hand',
      'How palm mounts affect personality',
      'Palmistry and career path interpretation',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Palmistry Articles')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (_, index) => ListTile(
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(articles[index]),
          subtitle: const Text('Tap to read with optional voice mode'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemCount: articles.length,
      ),
    );
  }
}
