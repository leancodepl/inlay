import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:leancode_add2app/leancode_add2app.dart';
import 'package:signal_module/src/cubits/sounds_notifications_cubit.dart';
import 'package:signal_module/src/generated/routes.g.dart';
import 'package:signal_module/src/generated/stores.g.dart';

import '../theme/signal_theme.dart';
import '../widgets/settings_tile.dart';

/// Sounds & Notifications screen backed by [SoundsNotificationsCubit].
///
/// The cubit handles loading the initial snapshot, cross-engine sync, and
/// persisting changes via the overridden [Add2AppCubit.emit].
class SoundsNotificationsScreen extends StatelessWidget {
  const SoundsNotificationsScreen({
    super.key,
    required this.contactId,
    this.preferences,
    this.presets,
    this.fallbackChannel,
  });

  final String contactId;
  final NotificationPreferences? preferences;
  final List<NotificationPreset>? presets;
  final DeliveryChannel? fallbackChannel;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SoundsNotificationsCubit(
        SoundsNotificationsStore(
          KeyValueStorage.instance,
          contactId: contactId,
        ),
      )..init(),
      child: const _SoundsNotificationsBody(),
    );
  }
}

class _SoundsNotificationsBody extends StatelessWidget {
  const _SoundsNotificationsBody();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sounds & Notifications'),
          leading: const IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: SystemNavigator.pop,
          ),
        ),
        body:
            BlocBuilder<
              SoundsNotificationsCubit,
              Add2AppState<SoundsNotificationsStoreSnapshot>
            >(
              builder: (context, state) => switch (state) {
                Add2AppStateLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
                Add2AppStateReady(:final data) => _ContentList(data: data),
              },
            ),
      ),
    );
  }
}

class _ContentList extends StatelessWidget {
  const _ContentList({required this.data});

  final SoundsNotificationsStoreSnapshot data;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cubit = context.read<SoundsNotificationsCubit>();

    return ListView(
      children: [
        const SizedBox(height: 8),

        SwitchListTile(
          secondary: Icon(
            data.mute ? Icons.notifications_off : Icons.notifications,
            color: isDark
                ? SignalColors.textSecondaryDark
                : SignalColors.textSecondaryLight,
          ),
          title: const Text('Mute notifications'),
          subtitle: data.mute ? const Text('Notifications are muted') : null,
          value: data.mute,
          onChanged: (_) => cubit.toggleMute(),
        ),

        const Divider(indent: 56),

        SettingsTile(
          icon: Icons.music_note_outlined,
          title: 'Notification sound',
          subtitle: data.sound,
          onTap: () => _showSoundPicker(context, cubit, data.sound),
        ),

        const Divider(indent: 56),

        SettingsTile(
          icon: Icons.vibration,
          title: 'Vibrate',
          subtitle: data.vibration.label,
          onTap: () => _showVibrationPicker(context, cubit, data.vibration),
        ),

        const Divider(indent: 56),

        SettingsTile(
          icon: Icons.tune,
          title: 'Notification behavior',
          subtitle: data.behavior.label,
          onTap: () => _showBehaviorPicker(context, cubit, data.behavior),
        ),

        const SizedBox(height: 24),
        const SettingsSectionHeader(title: 'Message notifications'),

        SwitchListTile(
          secondary: Icon(
            Icons.visibility_outlined,
            color: isDark
                ? SignalColors.textSecondaryDark
                : SignalColors.textSecondaryLight,
          ),
          title: const Text('Show previews'),
          subtitle: const Text('Display message content in notifications'),
          value: data.showPreviews,
          onChanged: (v) => cubit.setShowPreviews(value: v),
        ),

        const SizedBox(height: 32),

        _RouteExtrasSection(
          preferences: _screenOf(context).preferences,
          presets: _screenOf(context).presets,
          fallbackChannel: _screenOf(context).fallbackChannel,
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'These settings override the default notification settings '
            'for this conversation.\n\n'
            'State is synced across all Flutter engines & Android via '
            'Add2AppCubit + KeyValueStorage.',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? SignalColors.textSecondaryDark
                  : SignalColors.textSecondaryLight,
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.open_in_new, size: 20),
            label: const Text('Open again (new activity / new engine)'),
            onPressed: () async {
              try {
                await Add2AppNavigator.instance.push(
                  SoundsNotificationsPage(contactId: _screenOf(context).contactId),
                );
              } on PlatformException catch (e) {
                debugPrint('Add2AppNavigator: $e');
              }
            },
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.phone_android, size: 20),
            label: const Text('Open native Sounds & Notifications'),
            onPressed: () async {
              try {
                await Add2AppNavigator.instance.push(
                  NativeEditProfilePage(
                    contactId: _screenOf(context).contactId,
                  ).toNativeRoute(),
                );
              } on PlatformException catch (e) {
                debugPrint('pushNativeRoute: $e');
              }
            },
          ),
        ),

        const SizedBox(height: 48),
      ],
    );
  }

  SoundsNotificationsScreen _screenOf(BuildContext context) {
    return context
        .findAncestorWidgetOfExactType<SoundsNotificationsScreen>()!;
  }
}

void _showSoundPicker(
  BuildContext context,
  SoundsNotificationsCubit cubit,
  String currentSound,
) {
  final sounds = ['Default', 'Signal', 'Pulse', 'Chime', 'Bamboo', 'None'];

  showModalBottomSheet<void>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Notification Sound',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          ...sounds.map(
            (sound) => ListTile(
              title: Text(sound),
              trailing: currentSound == sound
                  ? const Icon(Icons.check, color: SignalColors.signalBlue)
                  : null,
              onTap: () {
                cubit.changeSound(sound);
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}

void _showVibrationPicker(
  BuildContext context,
  SoundsNotificationsCubit cubit,
  VibrationLevel currentLevel,
) {
  const levels = VibrationLevel.values;

  showModalBottomSheet<void>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Vibration Pattern',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          ...levels.map(
            (level) => ListTile(
              title: Text(level.label),
              trailing: currentLevel == level
                  ? const Icon(Icons.check, color: SignalColors.signalBlue)
                  : null,
              onTap: () {
                cubit.changeVibration(level);
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}

void _showBehaviorPicker(
  BuildContext context,
  SoundsNotificationsCubit cubit,
  NotificationBehavior currentBehavior,
) {
  const behaviors = NotificationBehavior.values;

  showModalBottomSheet<void>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Notification Behavior',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          ...behaviors.map(
            (behavior) => ListTile(
              title: Text(behavior.label),
              trailing: currentBehavior == behavior
                  ? const Icon(Icons.check, color: SignalColors.signalBlue)
                  : null,
              onTap: () {
                cubit.changeBehavior(behavior);
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}

class _RouteExtrasSection extends StatelessWidget {
  const _RouteExtrasSection({
    this.preferences,
    this.presets,
    this.fallbackChannel,
  });

  final NotificationPreferences? preferences;
  final List<NotificationPreset>? presets;
  final DeliveryChannel? fallbackChannel;

  @override
  Widget build(BuildContext context) {
    final hasData =
        preferences != null || presets != null || fallbackChannel != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor =
        isDark ? SignalColors.textSecondaryDark : SignalColors.textSecondaryLight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        color: hasData
            ? (isDark ? const Color(0xFF1B3A1B) : const Color(0xFFE8F5E9))
            : (isDark ? const Color(0xFF3A1B1B) : const Color(0xFFFFF3E0)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasData
                    ? 'Route Extras (from native)'
                    : 'Route Extras (none passed)',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              if (!hasData)
                Text(
                  'No complex data was passed from native. '
                  'This section is empty when navigating within Flutter.',
                  style: TextStyle(fontSize: 12, color: subtitleColor),
                ),
              if (preferences != null) ...[
                Text(
                  'Preferences:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: subtitleColor,
                  ),
                ),
                Text(
                  '  sound: ${preferences!.sound.name}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  '  channels: ${preferences!.channels.map((c) => c.name).join(", ")}',
                  style: const TextStyle(fontSize: 12),
                ),
                if (preferences!.quietHours != null)
                  Text(
                    '  quietHours: ${preferences!.quietHours!.fromHour}:00 - ${preferences!.quietHours!.toHour}:00',
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
              if (presets != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Presets (${presets!.length}):',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: subtitleColor,
                  ),
                ),
                for (final preset in presets!)
                  Text(
                    '  "${preset.name}" — sound: ${preset.preferences.sound.name}',
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
              if (fallbackChannel != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Fallback channel: ${fallbackChannel!.name}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

extension on VibrationLevel {
  String get label => switch (this) {
    VibrationLevel.off => 'Off',
    VibrationLevel.normal => 'Normal',
    VibrationLevel.intense => 'Intense',
  };
}

extension on NotificationBehavior {
  String get label => switch (this) {
    NotificationBehavior.defaultBehavior => 'Default',
    NotificationBehavior.mentionsOnly => 'Mentions only',
    NotificationBehavior.muted => 'Muted',
  };
}
