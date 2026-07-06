import 'package:flutter/material.dart';

class ConfirmActionContent extends StatelessWidget {
  const ConfirmActionContent({super.key, required this.action, this.message});

  final String action;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Confirm $action'),
      content: message != null ? Text(message!) : null,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
