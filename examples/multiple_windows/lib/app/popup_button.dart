// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'package:flutter/src/widgets/_window.dart';
import 'package:flutter/src/widgets/view.dart';
import 'package:material_ui/material_ui.dart';

import 'models.dart';
import 'popup_window_content.dart';

class PopupButton extends StatefulWidget {
  const PopupButton({super.key, required this.parentController});

  final BaseWindowController parentController;

  @override
  State<PopupButton> createState() => _PopupButtonState();
}

class _PopupButtonState extends State<PopupButton> {
  bool showPopup = false;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () => setState(() => showPopup = !showPopup),
      child: ViewAnchorLayoutBuilder(
        viewBuilder: (BuildContext context, ViewAnchorLayoutInfo info) {
          if (!showPopup) {
            return null;
          }

          return _PopupWindow(
            parent: widget.parentController,
            windowSettings: WindowSettingsAccessor.of(context),
            anchorRect: info.childRect,
            onDestroyed: () {
              if (mounted) {
                setState(() => showPopup = false);
              }
            },
          );
        },
        child: Text(showPopup ? 'Hide Popup' : 'Show Popup'),
      ),
    );
  }
}

class _PopupWindow extends StatefulWidget {
  const _PopupWindow({
    required this.parent,
    required this.windowSettings,
    required this.anchorRect,
    required this.onDestroyed,
  });

  final BaseWindowController parent;
  final WindowSettings windowSettings;
  final Rect anchorRect;

  /// Called when the popup window is destroyed by the platform, for example
  /// when another window receives input focus.
  final VoidCallback onDestroyed;

  @override
  State<_PopupWindow> createState() => _PopupWindowState();
}

class _PopupWindowState extends State<_PopupWindow> {
  late final PopupWindowController controller;
  bool _destroyed = false;

  @override
  void initState() {
    super.initState();
    controller = PopupWindowController(
      parent: widget.parent,
      anchorRect: widget.anchorRect,
      positioner: widget.windowSettings.positioner,
      delegate: _PopupWindowControllerDelegate(
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
  void didUpdateWidget(covariant _PopupWindow oldWidget) {
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
    return PopupWindow(
      controller: controller,
      child: PopupWindowContent(controller: controller),
    );
  }
}

class _PopupWindowControllerDelegate extends PopupWindowControllerDelegate {
  _PopupWindowControllerDelegate({required this.onDestroyed});

  @override
  void onWindowDestroyed() {
    onDestroyed();
    super.onWindowDestroyed();
  }

  final VoidCallback onDestroyed;
}
