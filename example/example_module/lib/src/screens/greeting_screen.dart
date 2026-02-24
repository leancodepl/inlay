import 'package:flutter/material.dart';
import 'package:leancode_add2app/leancode_add2app.dart';

import '../generated/routes.g.dart';

class GreetingScreen extends StatelessWidget {
  const GreetingScreen({super.key, required this.name, required this.style});

  final String name;
  final GreetingStyle? style;

  @override
  Widget build(BuildContext context) {
    final greeting = switch (style) {
      GreetingStyle.formal => 'Hello, $name.',
      GreetingStyle.casual => 'Hi $name!',
      null => 'Welcome, $name!',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Greeting')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(greeting, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                Add2AppNavigator.instance.push(const CounterPage());
              },
              child: const Text('Open Counter (new Flutter engine)'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                Add2AppNavigator.instance.push(
                  const ProfilePage(
                    userId: '42',
                    badges: [
                      UserBadge(label: 'Helper', level: BadgeLevel.silver),
                    ],
                  ),
                );
              },
              child: const Text('Open Profile (new Flutter engine)'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Add2AppNavigator.instance.push(
                  const NativeAboutPage(appVersion: '1.0.0').toNativeRoute(),
                );
              },
              child: const Text('Open native About screen'),
            ),
          ],
        ),
      ),
    );
  }
}
