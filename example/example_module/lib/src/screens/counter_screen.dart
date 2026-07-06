import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inlay/inlay.dart';

import '../cubits/counter_cubit.dart';
import '../generated/routes.g.dart';
import '../generated/stores.g.dart';

class CounterScreen extends StatelessWidget {
  const CounterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          CounterCubit(CounterStore(KeyValueStorage.instance))..init(),
      child: BlocBuilder<CounterCubit, InlayState<CounterStoreSnapshot>>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final snapshot = state.requireData;
          final cubit = context.read<CounterCubit>();
          return Scaffold(
            appBar: AppBar(
              leading: BackButton(
                onPressed: () => InlayNavigator.instance.maybePop(context),
              ),
              title: const Text('Counter'),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Count: ${snapshot.count}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text('Last updated by: ${snapshot.lastUpdatedBy}'),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilledButton(
                        onPressed: cubit.increment,
                        child: const Text('+'),
                      ),
                      FilledButton(
                        onPressed: cubit.decrement,
                        child: const Text('-'),
                      ),
                      OutlinedButton(
                        onPressed: cubit.reset,
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      const page = ProfilePage(
                        userId: '42',
                        badges: [
                          UserBadge(
                            label: 'In-Flutter demo',
                            level: BadgeLevel.bronze,
                          ),
                        ],
                      );
                      context.push(page.toPath(), extra: page);
                    },
                    child: const Text('Open Profile (same Flutter stack)'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {
                      InlayNavigator.instance.push(
                        const NativeSettingsPage().toNativeRoute(),
                      );
                    },
                    child: const Text('Open native Settings screen'),
                  ),
                  const SizedBox(height: 8),
                  // Closes this engine's container and returns the count to
                  // whoever opened it with pushForResult / onResult.
                  FilledButton(
                    onPressed: () => CounterPage.popWithResult(snapshot.count),
                    child: const Text('Done — return count to caller'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
