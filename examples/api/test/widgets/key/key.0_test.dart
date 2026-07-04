// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_api_samples/widgets/key/key.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Two colored boxes and a swap button are shown', (WidgetTester tester) async {
    await tester.pumpWidget(const example.KeyExampleApp());

    expect(find.byType(example.RandomColor), findsNWidgets(2));
    expect(find.text('Press me'), findsOneWidget);
  });

  testWidgets('Without keys: colors stay in place after swap', (WidgetTester tester) async {
    await tester.pumpWidget(_buildApp(keysEnabled: false));

    List<Container> boxes = tester.widgetList<Container>(find.byType(Container)).toList();
    final Color colorAtPosition0 = boxes[0].color!;
    final Color colorAtPosition1 = boxes[1].color!;

    await tester.tap(find.text('Press me'));
    await tester.pump();

    // Without keys, State (color) stays at its original position in the tree.
    boxes = tester.widgetList<Container>(find.byType(Container)).toList();
    expect(boxes[0].color, colorAtPosition0);
    expect(boxes[1].color, colorAtPosition1);
  });

  testWidgets('With keys: colors follow their boxes after swap', (WidgetTester tester) async {
    await tester.pumpWidget(_buildApp(keysEnabled: true));

    List<Container> boxes = tester.widgetList<Container>(find.byType(Container)).toList();
    final Color colorAtPosition0 = boxes[0].color!;
    final Color colorAtPosition1 = boxes[1].color!;

    await tester.tap(find.text('Press me'));
    await tester.pump();

    // With keys, State (color) follows the widget to its new position.
    boxes = tester.widgetList<Container>(find.byType(Container)).toList();
    expect(boxes[0].color, colorAtPosition1);
    expect(boxes[1].color, colorAtPosition0);
  });
}

Widget _buildApp({required bool keysEnabled}) {
  return WidgetsApp(
    color: const Color(0xFFFFFFFF),
    builder: (BuildContext context, Widget? navigator) {
      return example.KeyExample(keysEnabled: keysEnabled);
    },
  );
}
