import 'package:flutter/material.dart';

import '../models/contact.dart';
import '../theme/signal_theme.dart';
import '../widgets/action_button.dart';
import '../widgets/avatar.dart';
import '../widgets/settings_tile.dart';
import 'sounds_notifications_screen.dart';

/// Contact Details screen - shows contact profile and settings
class ContactDetailsScreen extends StatefulWidget {
  const ContactDetailsScreen({
    super.key,
    required this.contactId,
    this.contact,
  });

  final String contactId;
  final Contact? contact;

  @override
  State<ContactDetailsScreen> createState() => _ContactDetailsScreenState();
}

class _ContactDetailsScreenState extends State<ContactDetailsScreen> {
  late Contact _contact;
  var _isBlocked = false;

  @override
  void initState() {
    super.initState();
    // Use provided contact or mock data
    _contact = widget.contact ?? MockContacts.alice;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: isDark
                ? SignalColors.darkSurface
                : SignalColors.lightSurface,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: _onEditProfile,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildProfileHeader(context),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: ActionButtonRow(
                    children: [
                      CircleActionButton(
                        icon: Icons.message_outlined,
                        label: 'Message',
                        onTap: _onMessage,
                      ),
                      CircleActionButton(
                        icon: Icons.videocam_outlined,
                        label: 'Video',
                        onTap: _onVideoCall,
                      ),
                      CircleActionButton(
                        icon: Icons.call_outlined,
                        label: 'Call',
                        onTap: _onVoiceCall,
                      ),
                      CircleActionButton(
                        icon: Icons.more_horiz,
                        label: 'More',
                        onTap: _onMoreOptions,
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                SettingsTile(
                  icon: Icons.timer_outlined,
                  title: 'Disappearing messages',
                  subtitle: _contact.disappearingMessagesFormatted ?? 'Off',
                  onTap: _onDisappearingMessages,
                ),
                const SettingsDivider(),

                SettingsTile(
                  icon: Icons.edit_outlined,
                  title: 'Nickname',
                  subtitle: 'Add a nickname',
                  onTap: _onNickname,
                ),
                const SettingsDivider(),

                SettingsTile(
                  icon: Icons.palette_outlined,
                  title: 'Chat color and wallpaper',
                  onTap: _onChatColorWallpaper,
                ),
                const SettingsDivider(),

                SettingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Sounds & notifications',
                  subtitle: _contact.isMuted ? 'Muted' : null,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => SoundsNotificationsScreen(
                        contactId: _contact.id,
                      ),
                    ),
                  ),
                ),
                const SettingsDivider(),

                if (_contact.isVerified) ...[
                  SettingsTile(
                    icon: Icons.verified_user_outlined,
                    title: 'View safety number',
                    iconColor: SignalColors.signalBlue,
                    onTap: _onViewSafetyNumber,
                  ),
                  const SettingsDivider(),
                ],

                const SizedBox(height: 16),

                // Shared media section
                const SettingsSectionHeader(title: 'Shared media'),
                _buildSharedMediaPlaceholder(context),

                const SizedBox(height: 16),

                // Groups in common section
                const SettingsSectionHeader(title: 'Groups in common'),
                _buildGroupsInCommonPlaceholder(context),

                const SizedBox(height: 24),

                // Destructive actions
                SettingsTile(
                  icon: _isBlocked ? Icons.check_circle_outline : Icons.block,
                  title: _isBlocked ? 'Unblock' : 'Block',
                  destructive: !_isBlocked,
                  onTap: _onBlockToggle,
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? SignalColors.darkSurface : SignalColors.lightSurface,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar
              ProfileAvatar(
                initials: _contact.initials,
                imageUrl: _contact.avatarUrl,
              ),
              const SizedBox(height: 16),

              // Name
              Text(
                _contact.displayName,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? SignalColors.textPrimaryDark
                      : SignalColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 4),

              // Phone number
              if (_contact.phoneNumber != null)
                Text(
                  _contact.phoneNumber!,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? SignalColors.textSecondaryDark
                        : SignalColors.textSecondaryLight,
                  ),
                ),

              // About/status
              if (_contact.about != null) ...[
                const SizedBox(height: 8),
                Text(
                  _contact.about!,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? SignalColors.textSecondaryDark
                        : SignalColors.textSecondaryLight,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSharedMediaPlaceholder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark
            ? SignalColors.darkSurfaceElevated
            : SignalColors.lightBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              color: isDark
                  ? SignalColors.textSecondaryDark
                  : SignalColors.textSecondaryLight,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'No shared media yet',
              style: TextStyle(
                color: isDark
                    ? SignalColors.textSecondaryDark
                    : SignalColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupsInCommonPlaceholder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark
            ? SignalColors.darkSurfaceElevated
            : SignalColors.lightBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          'No groups in common',
          style: TextStyle(
            color: isDark
                ? SignalColors.textSecondaryDark
                : SignalColors.textSecondaryLight,
          ),
        ),
      ),
    );
  }

  // Action handlers
  void _onEditProfile() {
    debugPrint('Edit profile tapped');
  }

  void _onMessage() {
    // Pop back
    Navigator.of(context).pop();
  }

  void _onVideoCall() {
    debugPrint('Video call tapped');
  }

  void _onVoiceCall() {
    debugPrint('Voice call tapped');
  }

  void _onMoreOptions() {
    debugPrint('More options tapped');
  }

  void _onDisappearingMessages() {
    debugPrint('Disappearing messages tapped');
  }

  void _onNickname() {
    debugPrint('Nickname tapped');
  }

  void _onChatColorWallpaper() {
    // In a real app, this could navigate to a chat color & wallpaper screen
    debugPrint('Chat color & wallpaper tapped for contact: ${_contact.id}');
  }

  void _onViewSafetyNumber() {
    debugPrint('View safety number tapped');
  }

  void _onBlockToggle() {
    setState(() {
      _isBlocked = !_isBlocked;
    });
  }
}
