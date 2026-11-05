// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(loic-sharma): Remove this ignore when the windowing APIs are stable.
// ignore_for_file: invalid_use_of_internal_member

import 'dart:ui' show FlutterView;

import 'package:flutter/rendering.dart';
import 'package:flutter/src/foundation/_features.dart' show isWindowingEnabled;
import 'package:flutter/src/widgets/_window.dart'
    show BaseWindowController, TooltipWindow, TooltipWindowController;
import 'package:flutter/src/widgets/_window_positioner.dart';
import 'package:flutter/src/widgets/view.dart'
    show ViewAnchorLayoutBuilder, ViewAnchorLayoutInfo, ViewAnchorLayoutWidgetBuilder;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'multi_view_testing.dart';

void main() {
  // TooltipWindow throws if windowing is disabled.
  isWindowingEnabled = true;

  Widget buildAnchor({
    required ViewAnchorLayoutWidgetBuilder viewBuilder,
    EdgeInsets padding = const EdgeInsets.only(left: 10, top: 20),
    Size anchorSize = const Size(30, 40),
    Widget? child,
  }) {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: padding,
        child: ViewAnchorLayoutBuilder(
          viewBuilder: viewBuilder,
          child: child ?? SizedBox.fromSize(size: anchorSize),
        ),
      ),
    );
  }

  testWidgets('viewBuilder receives the child layout in the first frame', (
    WidgetTester tester,
  ) async {
    final sideView = FakeView(tester.view);
    final infos = <ViewAnchorLayoutInfo>[];

    await tester.pumpWidget(
      buildAnchor(
        viewBuilder: (BuildContext context, ViewAnchorLayoutInfo info) {
          infos.add(info);
          return View(view: sideView, child: const SizedBox.shrink());
        },
      ),
    );

    expect(infos, hasLength(1));
    expect(infos.single.childSize, const Size(30, 40));
    expect(infos.single.childRect, const Rect.fromLTWH(10, 20, 30, 40));
  });

  testWidgets('side views are laid out in the same frame as the viewBuilder', (
    WidgetTester tester,
  ) async {
    final sideView = FakeView(tester.view);
    final GlobalKey key = GlobalKey();

    await tester.pumpWidget(
      buildAnchor(
        viewBuilder: (BuildContext context, ViewAnchorLayoutInfo info) {
          return View(
            view: sideView,
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(key: key, width: info.childRect.right, height: 5),
            ),
          );
        },
      ),
    );

    final RenderBox box = tester.renderObject(find.byKey(key));
    expect(box.debugNeedsLayout, isFalse);
    expect(box.size, const Size(40, 5));
  });

  testWidgets('child layout is in logical pixels', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    final sideView = FakeView(tester.view);
    final infos = <ViewAnchorLayoutInfo>[];

    await tester.pumpWidget(
      buildAnchor(
        viewBuilder: (BuildContext context, ViewAnchorLayoutInfo info) {
          infos.add(info);
          return View(view: sideView, child: const SizedBox.shrink());
        },
      ),
    );

    expect(infos.single.childRect, const Rect.fromLTWH(10, 20, 30, 40));
  });

  testWidgets('viewBuilder is called in the same frame when the child is laid out again', (
    WidgetTester tester,
  ) async {
    final sideView = FakeView(tester.view);
    final infos = <ViewAnchorLayoutInfo>[];
    Widget build({required EdgeInsets padding}) {
      return buildAnchor(
        padding: padding,
        viewBuilder: (BuildContext context, ViewAnchorLayoutInfo info) {
          infos.add(info);
          return View(view: sideView, child: const SizedBox.shrink());
        },
      );
    }

    await tester.pumpWidget(build(padding: const EdgeInsets.only(left: 10, top: 20)));
    expect(infos.last.childRect, const Rect.fromLTWH(10, 20, 30, 40));

    await tester.pumpWidget(build(padding: const EdgeInsets.only(left: 50, top: 60)));
    expect(infos.last.childRect, const Rect.fromLTWH(50, 60, 30, 40));
  });

  testWidgets('viewBuilder is called in the same frame for paint-only changes', (
    WidgetTester tester,
  ) async {
    final sideView = FakeView(tester.view);
    final infos = <ViewAnchorLayoutInfo>[];
    final translation = ValueNotifier<Offset>(Offset.zero);
    addTearDown(translation.dispose);

    // The ViewAnchorLayoutBuilder is not rebuilt when the translation changes.
    await tester.pumpWidget(
      Align(
        alignment: Alignment.topLeft,
        child: ValueListenableBuilder<Offset>(
          valueListenable: translation,
          builder: (BuildContext context, Offset value, Widget? child) {
            return Transform.translate(offset: value, child: child);
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 10, top: 20),
            child: ViewAnchorLayoutBuilder(
              viewBuilder: (BuildContext context, ViewAnchorLayoutInfo info) {
                infos.add(info);
                return View(view: sideView, child: const SizedBox.shrink());
              },
              child: const SizedBox(width: 30, height: 40),
            ),
          ),
        ),
      ),
    );
    expect(infos, hasLength(1));
    expect(infos.last.childRect, const Rect.fromLTWH(10, 20, 30, 40));

    // Changing a Transform's transform only marks it as needing paint, so no
    // render object in the surrounding view is laid out again.
    translation.value = const Offset(100, 200);
    await tester.pump();

    expect(infos, hasLength(2));
    expect(infos.last.childRect, const Rect.fromLTWH(110, 220, 30, 40));
  });

  testWidgets('viewBuilder is not called if the child layout does not change', (
    WidgetTester tester,
  ) async {
    final sideView = FakeView(tester.view);
    var buildCount = 0;

    await tester.pumpWidget(
      buildAnchor(
        viewBuilder: (BuildContext context, ViewAnchorLayoutInfo info) {
          buildCount += 1;
          return View(view: sideView, child: const SizedBox.shrink());
        },
      ),
    );
    expect(buildCount, 1);

    await tester.pump();
    await tester.pump();
    expect(buildCount, 1);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('viewBuilder is called when the widget is updated', (WidgetTester tester) async {
    final sideView = FakeView(tester.view);
    final labels = <String>[];
    Widget build(String label) {
      return buildAnchor(
        viewBuilder: (BuildContext context, ViewAnchorLayoutInfo info) {
          labels.add(label);
          return View(view: sideView, child: const SizedBox.shrink());
        },
      );
    }

    await tester.pumpWidget(build('a'));
    await tester.pumpWidget(build('b'));
    expect(labels, <String>['a', 'b']);
  });

  testWidgets('side views are removed with the widget', (WidgetTester tester) async {
    final sideView = FakeView(tester.view);

    await tester.pumpWidget(
      buildAnchor(
        viewBuilder: (BuildContext context, ViewAnchorLayoutInfo info) {
          return View(view: sideView, child: const SizedBox.shrink());
        },
      ),
    );
    expect(
      tester.binding.renderViews.map((RenderView view) => view.flutterView),
      contains(sideView),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    expect(
      tester.binding.renderViews.map((RenderView view) => view.flutterView),
      isNot(contains(sideView)),
    );
  });

  testWidgets('viewBuilder can return null to build no side views', (WidgetTester tester) async {
    final sideView = FakeView(tester.view);
    final childKey = GlobalKey<_CounterState>();
    Iterable<FlutterView> renderedViews() =>
        tester.binding.renderViews.map((RenderView view) => view.flutterView);
    Widget build({required bool showSideView}) {
      return buildAnchor(
        viewBuilder: (BuildContext context, ViewAnchorLayoutInfo info) {
          if (!showSideView) {
            return null;
          }
          return View(view: sideView, child: const SizedBox.shrink());
        },
        child: _Counter(key: childKey),
      );
    }

    await tester.pumpWidget(build(showSideView: false));
    expect(tester.takeException(), isNull);
    expect(renderedViews(), isNot(contains(sideView)));
    final _CounterState state = childKey.currentState!;

    await tester.pumpWidget(build(showSideView: true));
    expect(renderedViews(), contains(sideView));
    expect(childKey.currentState, same(state));

    await tester.pumpWidget(build(showSideView: false));
    expect(renderedViews(), isNot(contains(sideView)));
    expect(childKey.currentState, same(state));
  });

  testWidgets('works with semantics enabled', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    final sideView = FakeView(tester.view);

    await tester.pumpWidget(
      buildAnchor(
        viewBuilder: (BuildContext context, ViewAnchorLayoutInfo info) {
          return View(
            view: sideView,
            child: const Directionality(textDirection: TextDirection.ltr, child: Text('Tooltip')),
          );
        },
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.semantics.byLabel('Tooltip'), findsOne);
    handle.dispose();
  });

  testWidgets('can create a tooltip window controller with the anchor rect', (
    WidgetTester tester,
  ) async {
    final controllers = <_RecordingTooltipWindowController>[];
    Widget build({required EdgeInsets padding}) {
      return buildAnchor(
        padding: padding,
        viewBuilder: (BuildContext context, ViewAnchorLayoutInfo info) {
          final Rect anchorRect = info.childRect;
          if (controllers.isEmpty) {
            controllers.add(
              _RecordingTooltipWindowController(
                rootView: FakeView(tester.view),
                anchorRect: anchorRect,
              ),
            );
          } else {
            controllers.single.updatePosition(anchorRect: anchorRect);
          }
          return TooltipWindow(
            controller: controllers.single,
            child: const Directionality(textDirection: TextDirection.ltr, child: Text('Tooltip')),
          );
        },
      );
    }

    await tester.pumpWidget(build(padding: const EdgeInsets.only(left: 10, top: 20)));
    expect(controllers, hasLength(1));
    expect(controllers.single.anchorRects, <Rect>[const Rect.fromLTWH(10, 20, 30, 40)]);
    expect(find.text('Tooltip'), findsOne);

    await tester.pumpWidget(build(padding: const EdgeInsets.only(left: 50, top: 60)));
    expect(controllers, hasLength(1));
    expect(controllers.single.anchorRects, <Rect>[
      const Rect.fromLTWH(10, 20, 30, 40),
      const Rect.fromLTWH(50, 60, 30, 40),
    ]);
  });
}

class _RecordingTooltipWindowController extends TooltipWindowController {
  _RecordingTooltipWindowController({required FlutterView rootView, required Rect anchorRect})
    : anchorRects = <Rect>[anchorRect],
      super.empty() {
    this.rootView = rootView;
  }

  final List<Rect> anchorRects;

  @override
  BaseWindowController get parent => throw UnimplementedError();

  @override
  Size get contentSize => Size.zero;

  @override
  void setConstraints(BoxConstraints constraints) {}

  @override
  void updatePosition({Rect? anchorRect, WindowPositioner? positioner}) {
    if (anchorRect != null) {
      anchorRects.add(anchorRect);
    }
  }

  @override
  bool get isDestroyed => _destroyed;
  bool _destroyed = false;

  @override
  void destroy() {
    _destroyed = true;
  }
}

class _Counter extends StatefulWidget {
  const _Counter({super.key});

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  @override
  Widget build(BuildContext context) => const SizedBox(width: 30, height: 40);
}
