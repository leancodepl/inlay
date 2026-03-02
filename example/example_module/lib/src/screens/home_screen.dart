import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../generated/routes.g.dart';

class ExampleHomeScreen extends StatelessWidget {
  const ExampleHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Example Module')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text('In-Flutter flow demo'),
            subtitle: const Text(
              'Native -> Flutter -> Flutter (same container)',
            ),
            onTap: () {
              const page = GreetingPage(
                name: 'Marcin',
                style: GreetingStyle.casual,
              );
              context.push(page.toPath(), extra: page);
            },
          ),
          ListTile(
            title: const Text('Greeting'),
            subtitle: const Text('Router path demo (replace current route)'),
            onTap: () => context.go(
              const GreetingPage(
                name: 'Marcin',
                style: GreetingStyle.casual,
              ).toPath(),
            ),
          ),
          ListTile(
            title: const Text('Counter'),
            subtitle: const Text('Router path demo (replace current route)'),
            onTap: () => context.go(const CounterPage().toPath()),
          ),
          ListTile(
            title: const Text('Profile'),
            subtitle: const Text('Router path demo (replace current route)'),
            onTap: () => context.go(
              const ProfilePage(
                userId: '42',
                badges: [
                  UserBadge(label: 'Early adopter', level: BadgeLevel.gold),
                ],
              ).toPath(),
            ),
          ),
        ],
      ),
    );
  }
}
