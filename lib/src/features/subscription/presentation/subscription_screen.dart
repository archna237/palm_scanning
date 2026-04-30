import 'package:flutter/material.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Go Premium')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Premium Plan', style: TextStyle(fontSize: 20)),
                    SizedBox(height: 8),
                    Text('- Unlimited hand scans'),
                    Text('- Full section insights'),
                    Text('- Compatibility deep report'),
                    Text('- No ads'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment flow to be integrated')),
                );
              },
              child: const Text('Start 3-Day Free Trial'),
            ),
          ],
        ),
      ),
    );
  }
}
