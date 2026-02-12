import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../navigator/add2app_navigator.dart';
import '../navigator/pages.dart';
import '../storage/key_value_storage.dart';
import '../theme/signal_theme.dart';
import '../widgets/settings_tile.dart';

/// Storage key helpers — namespaced per contact.
String _key(String contactId, String field) =>
    'sounds_notifications/$contactId/$field';

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
  final _storage = KeyValueStorage();

  var _muteNotifications = false;
  var _showPreviews = true;
  var _notificationSound = 'Default';
  var _vibrationPattern = 'Default';
  var _isLoading = true;

  StreamSubscription<List<StorageEntry>>? _sub;

  @override
  void initState() {
    super.initState();
    _loadFromStorage();
    _sub = _storage.stream.listen(_onStorageChanged);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  /// Read the latest values from the platform (async, always fresh).
  Future<void> _loadFromStorage() async {
    final mute = await _storage.getString(_key(widget.contactId, 'mute'));
    final sound = await _storage.getString(_key(widget.contactId, 'sound'));
    final vibration =
        await _storage.getString(_key(widget.contactId, 'vibration'));
    final previews =
        await _storage.getString(_key(widget.contactId, 'previews'));

    if (!mounted) {
      return;
    }

    setState(() {
      _muteNotifications = mute == 'true';
      _notificationSound = sound ?? 'Default';
      _vibrationPattern = vibration ?? 'Default';
      _showPreviews = previews != 'false';
      _isLoading = false;
    });
  }

  /// Called when storage changes from another engine or Android.
  /// (The framework never sends back our own writes.)
  void _onStorageChanged(List<StorageEntry> entries) {
    final prefix = 'sounds_notifications/${widget.contactId}/';
    final relevant = entries.where((e) => e.key.startsWith(prefix));
    if (relevant.isEmpty) {
      return;
    }

    // On a full-sync (resumed) we get all keys, so we reload everything.
    // For granular pushes we just update the changed fields.
    setState(() {
      for (final entry in relevant) {
        final field = entry.key.replaceFirst(prefix, '');
        switch (field) {
          case 'mute':
            _muteNotifications = entry.value == 'true';
          case 'sound':
            _notificationSound = entry.value.isEmpty ? 'Default' : entry.value;
          case 'vibration':
            _vibrationPattern = entry.value.isEmpty ? 'Default' : entry.value;
          case 'previews':
            _showPreviews = entry.value != 'false';
        }
      }
    });
  }

  // ── Write helpers (fire-and-forget, optimistic local update) ──────

  Future<void> _setMute(bool value) async {
    setState(() => _muteNotifications = value);
    await _storage.putString(_key(widget.contactId, 'mute'), value.toString());
  }

  Future<void> _setPreviews(bool value) async {
    setState(() => _showPreviews = value);
    await _storage.putString(
      _key(widget.contactId, 'previews'),
      value.toString(),
    );
  }

  Future<void> _setSound(String value) async {
    setState(() => _notificationSound = value);
    await _storage.putString(_key(widget.contactId, 'sound'), value);
  }

  Future<void> _setVibration(String value) async {
    setState(() => _vibrationPattern = value);
    await _storage.putString(_key(widget.contactId, 'vibration'), value);
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
                    subtitle: _vibrationPattern,
                    onTap: () => _showVibrationPicker(context),
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
                      label: const Text(
                        'Open native Sounds & Notifications',
                      ),
                      onPressed: () async {
                        try {
                          await Add2AppNavigator.instance.pushNativeRoute(
                            NativeEditProfilePage(
                              contactId: widget.contactId,
                            ),
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
    final patterns = ['Default', 'Short', 'Long', 'Double', 'None'];

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
            ...patterns.map(
              (pattern) => ListTile(
                title: Text(pattern),
                trailing: _vibrationPattern == pattern
                    ? const Icon(Icons.check, color: SignalColors.signalBlue)
                    : null,
                onTap: () {
                  _setVibration(pattern);
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
