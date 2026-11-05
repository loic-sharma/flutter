// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/_window.dart';
import 'package:flutter/src/widgets/_window_positioner.dart';
import 'package:flutter/src/widgets/view.dart';
import 'package:material_ui/material_ui.dart';

class MainControllerWindowDelegate with WindowControllerDelegate {
  @override
  void onWindowDestroyed() {
    super.onWindowDestroyed();
    ServicesBinding.instance.exitApplication(AppExitType.required);
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final controller = WindowController(
    size: const Size(200, 200),
    title: 'Main Window',
    delegate: MainControllerWindowDelegate(),
  );

  runWidget(Window(controller: controller, child: const MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool showPopup = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: ViewAnchorLayoutBuilder(
            viewBuilder: (BuildContext context, ViewAnchorLayoutInfo info) {
              if (!showPopup) {
                return null;
              }

              return MyPopupWindow(
                parent: WindowScope.of(context),
                anchorRect: info.childRect,
              );
            },
            child: OutlinedButton(
              onPressed: () => setState(() => showPopup = !showPopup),
              child: Text(showPopup ? 'Hide Popup' : 'Show Popup'),
            ),
          ),
        ),
      ),
    );
  }
}

class MyPopupWindow extends StatefulWidget {
  const MyPopupWindow({super.key, required this.parent, required this.anchorRect});

  final BaseWindowController parent;
  final Rect anchorRect;

  @override
  State<MyPopupWindow> createState() => _MyPopupWindowState();
}

class _MyPopupWindowState extends State<MyPopupWindow> {
  late final PopupWindowController controller;

  @override
  void initState() {
    super.initState();
    controller = PopupWindowController(
      parent: widget.parent,
      anchorRect: widget.anchorRect,
      positioner: const WindowPositioner(),
    );
  }

  @override
  void didUpdateWidget(covariant MyPopupWindow oldWidget) {
    super.didUpdateWidget(oldWidget);
    assert(oldWidget.parent == widget.parent);
    if (oldWidget.anchorRect != widget.anchorRect) {
      controller.updatePosition(anchorRect: widget.anchorRect);
    }
  }

  @override
  void dispose() {
    controller.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopupWindow(
      controller: controller,
      child: Material(child: Text('Popup at ${widget.anchorRect}')),
    );
  }
}
