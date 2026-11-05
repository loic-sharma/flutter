// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'package:flutter/src/widgets/_window.dart';
import 'package:flutter/src/widgets/view.dart';
import 'package:material_ui/material_ui.dart';

import 'models.dart';
import 'tooltip_window_content.dart';

class TooltipButton extends StatefulWidget {
  const TooltipButton({super.key, required this.parentController});

  final BaseWindowController parentController;

  @override
  State<TooltipButton> createState() => _TooltipButtonState();
}

class _TooltipButtonState extends State<TooltipButton> {
  bool showTooltip = false;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () => setState(() => showTooltip = !showTooltip),
      child: ViewAnchorLayoutBuilder(
        viewBuilder: (BuildContext context, ViewAnchorLayoutInfo info) {
          if (!showTooltip) {
            return null;
          }

          return _TooltipWindow(
            parent: widget.parentController,
            windowSettings: WindowSettingsAccessor.of(context),
            anchorRect: info.childRect,
            onDestroyed: () {
              if (mounted) {
                setState(() => showTooltip = false);
              }
            },
          );
        },
        child: Text(showTooltip ? 'Hide Tooltip' : 'Show Tooltip'),
      ),
    );
  }
}

class _TooltipWindow extends StatefulWidget {
  const _TooltipWindow({
    required this.parent,
    required this.windowSettings,
    required this.anchorRect,
    required this.onDestroyed,
  });

  final BaseWindowController parent;
  final WindowSettings windowSettings;
  final Rect anchorRect;

  /// Called when the tooltip window is destroyed by something other than this
  /// widget, for example when its parent window is destroyed.
  final VoidCallback onDestroyed;

  @override
  State<_TooltipWindow> createState() => _TooltipWindowState();
}

class _TooltipWindowState extends State<_TooltipWindow> {
  late final TooltipWindowController controller;
  bool _destroyed = false;

  @override
  void initState() {
    super.initState();
    controller = TooltipWindowController(
      parent: widget.parent,
      anchorRect: widget.anchorRect,
      positioner: widget.windowSettings.positioner,
      delegate: _TooltipWindowControllerDelegate(
        onDestroyed: () {
          // Ignore destruction initiated by this widget's dispose.
          if (_destroyed) {
            return;
          }
          _destroyed = true;
          widget.onDestroyed();
        },
      ),
    );
  }

  @override
  void didUpdateWidget(covariant _TooltipWindow oldWidget) {
    super.didUpdateWidget(oldWidget);
    assert(oldWidget.parent == widget.parent);
    if (oldWidget.anchorRect != widget.anchorRect && !_destroyed) {
      controller.updatePosition(anchorRect: widget.anchorRect);
    }
  }

  @override
  void dispose() {
    // TODO(loic-sharma): BaseWindowController.dispose should destroy the window.
    if (!_destroyed) {
      _destroyed = true;
      controller.destroy();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TooltipWindow(
      controller: controller,
      child: TooltipWindowContent(controller: controller),
    );
  }
}

class _TooltipWindowControllerDelegate extends TooltipWindowControllerDelegate {
  _TooltipWindowControllerDelegate({required this.onDestroyed});

  @override
  void onWindowDestroyed() {
    onDestroyed();
    super.onWindowDestroyed();
  }

  final VoidCallback onDestroyed;
}
