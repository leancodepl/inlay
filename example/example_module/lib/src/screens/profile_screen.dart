import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:leancode_add2app/leancode_add2app.dart';

import '../cubits/profile_cubit.dart';
import '../generated/routes.g.dart';
import '../generated/stores.g.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.userId, required this.badges});

  final String userId;
  final List<UserBadge> badges;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileCubit(
        UserPreferencesStore(KeyValueStorage.instance, userId: userId),
      )..init(),
      child:
          BlocBuilder<ProfileCubit, Add2AppState<UserPreferencesStoreSnapshot>>(
            builder: (context, state) {
              if (state.isLoading) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final snapshot = state.requireData;
              final cubit = context.read<ProfileCubit>();
              return Scaffold(
                appBar: AppBar(
                  leading: BackButton(
                    onPressed: () =>
                        Add2AppNavigator.instance.maybePop(context),
                  ),
                  title: Text('Profile $userId'),
                ),
                body: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Display name: ${snapshot.displayName}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('Email: ${snapshot.email}'),
                    const SizedBox(height: 8),
                    Text('Dark mode: ${snapshot.darkMode ? 'on' : 'off'}'),
                    const SizedBox(height: 8),
                    Text('Theme: ${snapshot.theme.name}'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => cubit.updateName('User $userId'),
                      child: const Text('Set default name'),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () =>
                          cubit.updateEmail('user$userId@example.com'),
                      child: const Text('Set demo email'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: cubit.toggleDarkMode,
                      child: const Text('Toggle dark mode'),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: AppTheme.values
                          .map(
                            (theme) => ChoiceChip(
                              label: Text(theme.name),
                              selected: snapshot.theme == theme,
                              onSelected: (_) => cubit.setTheme(theme),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: () {
                        const page = GreetingPage(
                          name: 'Nested Flutter',
                          style: GreetingStyle.formal,
                        );
                        context.push(page.toPath(), extra: page);
                      },
                      child: const Text('Open Greeting (same Flutter stack)'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Badges from route params',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    ...badges.map(
                      (badge) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(badge.label),
                        subtitle: Text('Level: ${badge.level.name}'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }
}
