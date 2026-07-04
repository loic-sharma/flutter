// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:flutter/widgets.dart';

/// Flutter code sample for [GlobalKey].

void main() => runApp(const GlobalKeyExampleApp());

class GlobalKeyExampleApp extends StatelessWidget {
  const GlobalKeyExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      color: const Color(0xFFFFFFFF),
      builder: (BuildContext context, Widget? navigator) {
        return const SafeArea(
          child: GlobalKeyExample(
            // TRY THIS: Change to false to see the color reset on each move.
            useGlobalKey: true,
          ),
        );
      },
    );
  }
}

class GlobalKeyExample extends StatefulWidget {
  const GlobalKeyExample({super.key, required this.useGlobalKey});

  final bool useGlobalKey;

  @override
  State<GlobalKeyExample> createState() => _GlobalKeyExampleState();
}

class _GlobalKeyExampleState extends State<GlobalKeyExample> {
  final GlobalKey<RandomColorState> _globalKey = GlobalKey<RandomColorState>();
  bool _inSlotA = true;

  @override
  Widget build(BuildContext context) {
    // This creates a row with two Slot widgets, one of which has a RandomColor
    // child. When the user taps the "Press me" text, the RandomColor widget is
    // moved to the other slot. The state (color) is preserved only if RandomColor
    // has a [GlobalKey].
    final RandomColor randomColor = RandomColor(
      key: widget.useGlobalKey ? _globalKey : null,
    );

    return Column(
      mainAxisAlignment: .center,
      spacing: 24.0,
      children: <Widget>[
        Row(
          mainAxisAlignment: .center,
          spacing: 16.0,
          children: <Widget>[
            Slot(label: 'Slot A', child: _inSlotA ? randomColor : null),
            Slot(label: 'Slot B', child: _inSlotA ? null : randomColor),
          ],
        ),
        GestureDetector(
          onTap: () => setState(() => _inSlotA = !_inSlotA),
          child: const Text('Move'),
        ),
      ],
    );
  }
}

class Slot extends StatelessWidget {
  const Slot({super.key, required this.label, required this.child});

  final String label;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8.0,
      children: <Widget>[
        Text(label),
        Container(
          decoration: BoxDecoration(
            border: .all(color: const Color(0xFF9E9E9E)),
          ),
          width: 110.0,
          height: 110.0,
          child: Center(child: child),
        ),
      ],
    );
  }
}

class RandomColor extends StatefulWidget {
  const RandomColor({super.key});

  @override
  State<RandomColor> createState() => RandomColorState();
}

class RandomColorState extends State<RandomColor> {
  late final Color color;

  @override
  void initState() {
    super.initState();
    final hue = Random().nextDouble() * 360.0;
    color = HSVColor.fromAHSV(1.0, hue, 0.7, 0.8).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return Container(width: 100.0, height: 100.0, color: color);
  }
}
