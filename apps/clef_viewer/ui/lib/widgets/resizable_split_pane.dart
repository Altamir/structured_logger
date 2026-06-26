import 'package:flutter/material.dart';

import '../theme/clef_design_system.dart';

/// Horizontal split pane with drag-to-resize and optional left-panel collapse.
class ResizableSplitPane extends StatefulWidget {
  final Widget left;
  final Widget right;
  final double initialLeftWidth;
  final double minLeftWidth;
  final double maxLeftWidth;
  final bool collapsible;

  const ResizableSplitPane({
    super.key,
    required this.left,
    required this.right,
    this.initialLeftWidth = ClefDs.groupPanelDefaultWidth,
    this.minLeftWidth = ClefDs.groupPanelMinWidth,
    this.maxLeftWidth = ClefDs.groupPanelMaxWidth,
    this.collapsible = true,
  });

  @override
  State<ResizableSplitPane> createState() => _ResizableSplitPaneState();
}

class _ResizableSplitPaneState extends State<ResizableSplitPane> {
  late double _leftWidth;
  bool _collapsed = false;
  double? _widthBeforeCollapse;

  @override
  void initState() {
    super.initState();
    _leftWidth = widget.initialLeftWidth;
  }

  void _onDragUpdate(double delta, double maxWidth) {
    setState(() {
      _collapsed = false;
      _leftWidth = (_leftWidth + delta).clamp(
        widget.minLeftWidth,
        maxWidth.clamp(widget.minLeftWidth, widget.maxLeftWidth),
      );
    });
  }

  void _toggleCollapse() {
    setState(() {
      if (_collapsed) {
        _collapsed = false;
        _leftWidth = _widthBeforeCollapse ?? widget.initialLeftWidth;
      } else {
        _widthBeforeCollapse = _leftWidth;
        _collapsed = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxLeft = constraints.maxWidth * 0.55;
        final effectiveMax = maxLeft.clamp(
          widget.minLeftWidth,
          widget.maxLeftWidth,
        );
        final leftWidth = _collapsed
            ? ClefDs.groupPanelCollapsedWidth
            : _leftWidth.clamp(widget.minLeftWidth, effectiveMax);

        return Row(
          children: [
            SizedBox(
              width: leftWidth,
              child: _collapsed
                  ? _CollapsedStrip(onExpand: _toggleCollapse)
                  : widget.left,
            ),
            _SplitHandle(
              collapsed: _collapsed,
              onDrag: (delta) => _onDragUpdate(delta, effectiveMax),
              onToggleCollapse: widget.collapsible ? _toggleCollapse : null,
            ),
            Expanded(child: widget.right),
          ],
        );
      },
    );
  }
}

class _CollapsedStrip extends StatelessWidget {
  final VoidCallback onExpand;

  const _CollapsedStrip({required this.onExpand});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: onExpand,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          child: Column(
            children: [
              IconButton(
                tooltip: 'Expandir painel de grupos',
                onPressed: onExpand,
                icon: const Icon(Icons.chevron_right),
              ),
              const Expanded(
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    'Groups',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplitHandle extends StatefulWidget {
  final ValueChanged<double> onDrag;
  final VoidCallback? onToggleCollapse;
  final bool collapsed;

  const _SplitHandle({
    required this.onDrag,
    required this.collapsed,
    this.onToggleCollapse,
  });

  @override
  State<_SplitHandle> createState() => _SplitHandleState();
}

class _SplitHandleState extends State<_SplitHandle> {
  bool _hovering = false;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final active = _hovering || _dragging;

    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onHorizontalDragStart: (_) => setState(() => _dragging = true),
        onHorizontalDragUpdate: (d) => widget.onDrag(d.delta.dx),
        onHorizontalDragEnd: (_) => setState(() => _dragging = false),
        child: Container(
          width: ClefDs.splitHandleWidth,
          color: active
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.25)
              : Colors.transparent,
          child: Center(
            child: widget.onToggleCollapse != null
                ? Tooltip(
                    message: widget.collapsed
                        ? 'Expandir painel'
                        : 'Recolher painel',
                    child: GestureDetector(
                      onTap: widget.onToggleCollapse,
                      child: Container(
                        width: 4,
                        height: 32,
                        decoration: BoxDecoration(
                          color: active
                              ? Theme.of(context).colorScheme.primary
                              : ClefDs.appleGrayFill2,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  )
                : Container(
                    width: 2,
                    height: 32,
                    decoration: BoxDecoration(
                      color: ClefDs.appleGrayFill2,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}