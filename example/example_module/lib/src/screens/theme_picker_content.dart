import 'package:flutter/material.dart';

class ThemePickerContent extends StatelessWidget {
  const ThemePickerContent({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      maxChildSize: 0.6,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Pick a theme for user $userId',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  for (final theme in ['Light', 'Dark', 'System'])
                    ListTile(
                      title: Text(theme),
                      leading: const Icon(Icons.color_lens),
                      onTap: () => Navigator.pop(context),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
