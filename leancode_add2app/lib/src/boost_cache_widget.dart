import 'package:flutter/widgets.dart';

class BoostCacheWidget extends StatefulWidget {
  const BoostCacheWidget({
    required this.uniqueId,
    required this.builder,
    super.key,
  });

  final String uniqueId;
  final WidgetBuilder builder;

  @override
  State<BoostCacheWidget> createState() => _BoostCacheWidgetState();
}

class _BoostCacheWidgetState extends State<BoostCacheWidget> {
  late Widget _cacheWidget;
  String? _oldUniqueId;

  @override
  Widget build(BuildContext context) {
    final shouldUpdate = _oldUniqueId != widget.uniqueId;
    if (shouldUpdate) {
      _oldUniqueId = widget.uniqueId;
      _cacheWidget = widget.builder(context);
    }
    return _cacheWidget;
  }
}
