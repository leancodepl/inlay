import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inlay/inlay.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../generated/routes.g.dart';

class GreetingScreen extends StatefulWidget {
  const GreetingScreen({super.key, required this.name, required this.style});

  final String name;
  final GreetingStyle? style;

  @override
  State<GreetingScreen> createState() => _GreetingScreenState();
}

class _GreetingScreenState extends State<GreetingScreen> {
  // package_info_plus talks to the host over a platform channel, so this
  // call only works when the host registered plugins on this engine
  // (setOnEngineCreated on iOS, automatic on Android).
  PackageInfo? _packageInfo;

  // Last value returned by a screen opened for a result.
  String? _lastResult;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() => _packageInfo = info);
      }
    });
  }

  void _showResult(String label, Object? value) {
    if (mounted) {
      setState(() => _lastResult = '$label: ${value ?? '(dismissed)'}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final greeting = switch (widget.style) {
      GreetingStyle.formal => 'Hello, ${widget.name}.',
      GreetingStyle.casual => 'Hi ${widget.name}!',
      null => 'Welcome, ${widget.name}!',
    };
    final packageInfo = _packageInfo;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => InlayNavigator.instance.maybePop(context),
        ),
        title: const Text('Greeting'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(greeting, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                const page = CounterPage();
                context.push(page.toPath(), extra: page);
              },
              child: const Text('Open Counter (same Flutter stack)'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                const page = ProfilePage(
                  userId: '42',
                  badges: [
                    UserBadge(label: 'Helper', level: BadgeLevel.silver),
                  ],
                );
                context.push(page.toPath(), extra: page);
              },
              child: const Text('Open Profile (same Flutter stack)'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () async {
                // Flutter -> Flutter (new engine) -> typed result back.
                final count = await const CounterPage().pushForResult();
                _showResult('Counter returned', count);
              },
              child: const Text('Open Counter (new engine, await result)'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                InlayNavigator.instance.push(
                  const ProfilePage(
                    userId: '42',
                    badges: [
                      UserBadge(label: 'Helper', level: BadgeLevel.silver),
                    ],
                  ),
                );
              },
              child: const Text('Open Profile (new engine/container)'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: packageInfo == null
                  ? null
                  : () async {
                      // Flutter -> native -> typed result back.
                      final feedback = await NativeAboutPage(
                        appVersion: packageInfo.version,
                      ).pushForResult();
                      _showResult('About returned', feedback);
                    },
              child: const Text('Open native About (await result)'),
            ),
            const Spacer(),
            if (_lastResult != null)
              Text(_lastResult!, style: Theme.of(context).textTheme.titleSmall),
            Text(
              'Locale: ${Localizations.localeOf(context)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              packageInfo == null
                  ? 'Reading host app info...'
                  : 'Host app: ${packageInfo.appName} '
                        '${packageInfo.version}+${packageInfo.buildNumber} '
                        '(${packageInfo.packageName})',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
