// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:flutter/widgets.dart';

/// Flutter code sample for [Key].

void main() => runApp(const KeyExampleApp());

class KeyExampleApp extends StatelessWidget {
  const KeyExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      color: const Color(0xFFFFFFFF),
      builder: (BuildContext context, Widget? navigator) {
        return const SafeArea(
          child: KeyExample(
            // TRY THIS: Change to false to see how the boxes behave without keys.
            useKeys: true,
          ),
        );
      },
    );
  }
}

class KeyExample extends StatefulWidget {
  const KeyExample({super.key, required this.useKeys});

  final bool useKeys;

  @override
  State<KeyExample> createState() => _KeyExampleState();
}

class _KeyExampleState extends State<KeyExample> {
  bool _swap = false;

  @override
  Widget build(BuildContext context) {
    // This creates a row with two randomly colored boxes. When the user taps
    // the "Press me" text, the two boxes swap places. With keys, the state
    // (color) swaps with the boxes. Without keys, Flutter matches widgets by
    // position, so the colors do not swap.
    final boxA = RandomColor(key: widget.useKeys ? ValueKey('A') : null);
    final boxB = RandomColor(key: widget.useKeys ? ValueKey('B') : null);
    final children = _swap ? [boxB, boxA] : [boxA, boxB];

    return Column(
      mainAxisAlignment: .center,
      spacing: 16.0,
      children: [
        Row(mainAxisAlignment: .center, children: children),
        GestureDetector(
          onTap: () => setState(() => _swap = !_swap),
          child: const Text('Press me'),
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
  late final Color _color;

  @override
  void initState() {
    super.initState();
    final hue = Random().nextDouble() * 360.0;
    _color = HSVColor.fromAHSV(1.0, hue, 0.7, 0.8).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return Container(width: 100.0, height: 100.0, color: _color);
  }
}
