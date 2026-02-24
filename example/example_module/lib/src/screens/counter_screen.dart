import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:leancode_add2app/leancode_add2app.dart';

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
      child: BlocBuilder<CounterCubit, Add2AppState<CounterStoreSnapshot>>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final snapshot = state.requireData;
          final cubit = context.read<CounterCubit>();
          return Scaffold(
            appBar: AppBar(title: const Text('Counter')),
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
                      Add2AppNavigator.instance.push(
                        const NativeSettingsPage().toNativeRoute(),
                      );
                    },
                    child: const Text('Open native Settings screen'),
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
