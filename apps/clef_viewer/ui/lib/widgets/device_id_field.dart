import 'package:flutter/material.dart';

import '../models/filter_constants.dart';
import '../services/device_suggestion_cache.dart';

class DeviceIdField extends StatefulWidget {
  final TextEditingController controller;
  final DeviceSuggestionCache cache;
  final ValueChanged<String?> onDeviceSelected;

  const DeviceIdField({
    super.key,
    required this.controller,
    required this.cache,
    required this.onDeviceSelected,
  });

  @override
  State<DeviceIdField> createState() => _DeviceIdFieldState();
}

class _DeviceIdFieldState extends State<DeviceIdField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: RawAutocomplete<String>(
        textEditingController: widget.controller,
        focusNode: _focusNode,
        optionsBuilder: (textEditingValue) {
          return widget.cache.search(textEditingValue.text);
        },
        onSelected: (selection) {
          if (selection == '(empty)') {
            widget.controller.text = '(empty)';
            widget.onDeviceSelected(FilterConstants.emptySentinel);
          } else {
            widget.controller.text = selection;
            widget.onDeviceSelected(selection);
          }
        },
        fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
          return TextField(
            controller: textController,
            focusNode: focusNode,
            decoration: const InputDecoration(
              labelText: 'Device ID',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => onFieldSubmitted(),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200, maxWidth: 240),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    return ListTile(
                      dense: true,
                      title: Text(option),
                      onTap: () => onSelected(option),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}