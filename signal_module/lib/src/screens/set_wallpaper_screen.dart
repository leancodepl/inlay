import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:leancode_add2app/leancode_add2app.dart';
import 'package:signal_module/src/generated/routes.g.dart';

import '../models/wallpaper.dart';
import '../theme/signal_theme.dart';
import '../widgets/wallpaper_preview.dart';

/// Set Wallpaper screen
class SetWallpaperScreen extends StatefulWidget {
  const SetWallpaperScreen({
    super.key,
    this.recipientId,
    this.currentWallpaperId,
  });

  /// If null, setting wallpaper for all chats
  /// This is the recipient/thread ID from both iOS and Android
  final String? recipientId;
  final String? currentWallpaperId;

  @override
  State<SetWallpaperScreen> createState() => _SetWallpaperScreenState();
}

class _SetWallpaperScreenState extends State<SetWallpaperScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String? _selectedWallpaperId;
  var _dimInDarkMode = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedWallpaperId = widget.currentWallpaperId;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Wallpaper? get _selectedWallpaper {
    if (_selectedWallpaperId == null) {
      return null;
    }
    return PresetWallpapers.byId(_selectedWallpaperId!);
  }

  List<Wallpaper> get _solidColors =>
      PresetWallpapers.all.whereType<SolidColorWallpaper>().toList();

  List<Wallpaper> get _gradients =>
      PresetWallpapers.all.whereType<GradientWallpaper>().toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Set Wallpaper'),
          leading: const IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: SystemNavigator.pop,
          ),
          bottom: TabBar(
            controller: _tabController,
            labelColor: SignalColors.signalBlue,
            unselectedLabelColor: isDark
                ? SignalColors.textSecondaryDark
                : SignalColors.textSecondaryLight,
            indicatorColor: SignalColors.signalBlue,
            tabs: const [
              Tab(text: 'Solid Colors'),
              Tab(text: 'Gradients'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Preview area
            Expanded(flex: 2, child: _buildPreviewArea(context)),

            // Wallpaper selection
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  // Choose from photos option
                  ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark
                            ? SignalColors.darkSurfaceElevated
                            : SignalColors.lightBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.photo_library_outlined),
                    ),
                    title: const Text('Choose from photos'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _onChooseFromPhotos,
                  ),

                  const Divider(),

                  // Wallpaper grid
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Solid colors tab
                        SingleChildScrollView(
                          child: WallpaperGrid(
                            wallpapers: _solidColors,
                            selectedId: _selectedWallpaperId,
                            onSelect: _onSelectWallpaper,
                          ),
                        ),
                        // Gradients tab
                        SingleChildScrollView(
                          child: WallpaperGrid(
                            wallpapers: _gradients,
                            selectedId: _selectedWallpaperId,
                            onSelect: _onSelectWallpaper,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Dim in dark mode toggle
            if (_selectedWallpaper != null) ...[
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Dim wallpaper in dark mode'),
                value: _dimInDarkMode,
                onChanged: (value) {
                  setState(() => _dimInDarkMode = value);
                },
              ),
            ],

            // ADD2APP: Open same screen in new Activity (new engine) to spawn many engines
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.open_in_new, size: 20),
                label: const Text('Open again (new activity / new engine)'),
                onPressed: () async {
                  try {
                    await Add2AppNavigator.instance.push(
                      SetWallpaperPage(recipientId: widget.recipientId),
                    );
                  } on PlatformException catch (e) {
                    debugPrint('Add2AppNavigator: $e');
                  }
                },
              ),
            ),

            // ADD2APP: Open NATIVE comparison screen
            // (Flutter → native navigation via pushNativeRoute)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.phone_android, size: 20),
                label: const Text('Open native comparison screen'),
                onPressed: () async {
                  try {
                    await Add2AppNavigator.instance.push(
                      NativeMediaViewerPage(
                        mediaId: widget.recipientId ?? '1',
                      ).toNativeRoute(),
                    );
                  } on PlatformException catch (e) {
                    debugPrint('pushNativeRoute: $e');
                  }
                },
              ),
            ),

            // Set wallpaper button
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _selectedWallpaper != null
                        ? _onSetWallpaper
                        : null,
                    child: const Text('Set Wallpaper'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewArea(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget preview;
    if (_selectedWallpaper != null) {
      preview = WallpaperBackground(
        wallpaper: _selectedWallpaper!,
        child: _buildChatPreview(context),
      );
    } else {
      preview = Container(
        color: isDark
            ? SignalColors.darkBackground
            : SignalColors.lightBackground,
        child: _buildChatPreview(context),
      );
    }

    // Apply dim overlay if enabled and in dark mode
    if (_dimInDarkMode && isDark && _selectedWallpaper != null) {
      preview = Stack(
        children: [
          preview,
          Container(color: Colors.black.withValues(alpha: 0.3)),
          _buildChatPreview(context),
        ],
      );
    }

    return preview;
  }

  Widget _buildChatPreview(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Received message
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 250),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Hey! How are you?',
                style: TextStyle(color: Colors.black87),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Sent message
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 250),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: SignalColors.signalBlue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                "I'm doing great, thanks!",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onSelectWallpaper(Wallpaper wallpaper) {
    setState(() {
      _selectedWallpaperId = wallpaper.id;
    });
  }

  void _onChooseFromPhotos() {
    // In a real implementation, this would open the image picker
    debugPrint('Choose from photos tapped');
  }

  void _onSetWallpaper() {
    // In add2app we close the activity; result could be sent via method channel if needed
    SystemNavigator.pop();
  }
}
