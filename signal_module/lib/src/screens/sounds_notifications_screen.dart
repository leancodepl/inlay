import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:leancode_add2app/leancode_add2app.dart';
import 'package:signal_module/src/generated/routes.g.dart';
import 'package:signal_module/src/generated/stores.g.dart';

import '../theme/signal_theme.dart';
import '../widgets/settings_tile.dart';

/// Sounds & Notifications screen.
///
/// All state is stored on the platform via [KeyValueStorage].
/// Reads are async (always fresh), and changes from other engines/Android
/// arrive via the stream — the framework handles self-notification
/// suppression and lifecycle re-sync automatically.
class SoundsNotificationsScreen extends StatefulWidget {
  const SoundsNotificationsScreen({super.key, required this.contactId});

  final String contactId;

  @override
  State<SoundsNotificationsScreen> createState() =>
      _SoundsNotificationsScreenState();
}

class _SoundsNotificationsScreenState extends State<SoundsNotificationsScreen> {
  late final SoundsNotificationsStore _store;

  var _muteNotifications = false;
  var _showPreviews = true;
  var _notificationSound = 'Default';
  var _vibrationLevel = VibrationLevel.normal;
  var _behavior = NotificationBehavior.defaultBehavior;
  var _isLoading = true;

  StreamSubscription<SoundsNotificationsStoreSnapshot>? _sub;

  @override
  void initState() {
    super.initState();
    _store = SoundsNotificationsStore(
      KeyValueStorage.instance,
      contactId: widget.contactId,
    );
    _loadFromStore();
    _sub = _store.stream.listen(_onStoreSnapshot);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  /// Read latest values through generated typed store API.
  Future<void> _loadFromStore() async {
    final snapshot = await _store.getSnapshot();
    if (!mounted) {
      return;
    }
    _applySnapshot(snapshot);
  }

  /// Called when store snapshot changes from another engine or native app.
  void _onStoreSnapshot(SoundsNotificationsStoreSnapshot snapshot) {
    if (!mounted) {
      return;
    }
    _applySnapshot(snapshot);
  }

  void _applySnapshot(SoundsNotificationsStoreSnapshot snapshot) {
    setState(() {
      _muteNotifications = snapshot.mute;
      _showPreviews = snapshot.showPreviews;
      _notificationSound = snapshot.sound;
      _vibrationLevel = snapshot.vibration;
      _behavior = snapshot.behavior;
      _isLoading = false;
    });
  }

  // ── Write helpers (fire-and-forget, optimistic local update) ──────

  Future<void> _setMute(bool value) async {
    setState(() => _muteNotifications = value);
    await _store.setMute(value);
  }

  Future<void> _setPreviews(bool value) async {
    setState(() => _showPreviews = value);
    await _store.setShowPreviews(value);
  }

  Future<void> _setSound(String value) async {
    setState(() => _notificationSound = value);
    await _store.setSound(value);
  }

  Future<void> _setVibration(VibrationLevel value) async {
    setState(() => _vibrationLevel = value);
    await _store.setVibration(value);
  }

  Future<void> _setBehavior(NotificationBehavior value) async {
    setState(() => _behavior = value);
    await _store.setBehavior(value);
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  const SizedBox(height: 8),

                  // Mute toggle
                  SwitchListTile(
                    secondary: Icon(
                      _muteNotifications
                          ? Icons.notifications_off
                          : Icons.notifications,
                      color: isDark
                          ? SignalColors.textSecondaryDark
                          : SignalColors.textSecondaryLight,
                    ),
                    title: const Text('Mute notifications'),
                    subtitle: _muteNotifications
                        ? const Text('Notifications are muted')
                        : null,
                    value: _muteNotifications,
                    onChanged: _setMute,
                  ),

                  const Divider(indent: 56),

                  SettingsTile(
                    icon: Icons.music_note_outlined,
                    title: 'Notification sound',
                    subtitle: _notificationSound,
                    onTap: () => _showSoundPicker(context),
                  ),

                  const Divider(indent: 56),

                  SettingsTile(
                    icon: Icons.vibration,
                    title: 'Vibrate',
                    subtitle: _vibrationLevel.label,
                    onTap: () => _showVibrationPicker(context),
                  ),

                  const Divider(indent: 56),

                  SettingsTile(
                    icon: Icons.tune,
                    title: 'Notification behavior',
                    subtitle: _behavior.label,
                    onTap: () => _showBehaviorPicker(context),
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
                    subtitle: const Text(
                      'Display message content in notifications',
                    ),
                    value: _showPreviews,
                    onChanged: _setPreviews,
                  ),

                  const SizedBox(height: 32),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'These settings override the default notification settings '
                      'for this conversation.\n\n'
                      'State is synced across all Flutter engines & Android via '
                      'Pigeon KeyValueStorage.',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? SignalColors.textSecondaryDark
                            : SignalColors.textSecondaryLight,
                      ),
                    ),
                  ),

                  // ADD2APP: Open same screen in new Activity (new engine)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.open_in_new, size: 20),
                      label: const Text(
                        'Open again (new activity / new engine)',
                      ),
                      onPressed: () async {
                        try {
                          await Add2AppNavigator.instance.push(
                            SoundsNotificationsPage(
                              contactId: widget.contactId,
                            ),
                          );
                        } on PlatformException catch (e) {
                          debugPrint('Add2AppNavigator: $e');
                        }
                      },
                    ),
                  ),

                  // ADD2APP: Open NATIVE Sounds & Notifications screen
                  // (Flutter → native navigation via pushNativeRoute)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.phone_android, size: 20),
                      label: const Text('Open native Sounds & Notifications'),
                      onPressed: () async {
                        try {
                          await Add2AppNavigator.instance.push(
                            NativeEditProfilePage(
                              contactId: widget.contactId,
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
              ),
      ),
    );
  }

  void _showSoundPicker(BuildContext context) {
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
                trailing: _notificationSound == sound
                    ? const Icon(Icons.check, color: SignalColors.signalBlue)
                    : null,
                onTap: () {
                  _setSound(sound);
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

  void _showVibrationPicker(BuildContext context) {
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
                trailing: _vibrationLevel == level
                    ? const Icon(Icons.check, color: SignalColors.signalBlue)
                    : null,
                onTap: () {
                  _setVibration(level);
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

  void _showBehaviorPicker(BuildContext context) {
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
                trailing: _behavior == behavior
                    ? const Icon(Icons.check, color: SignalColors.signalBlue)
                    : null,
                onTap: () {
                  _setBehavior(behavior);
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
