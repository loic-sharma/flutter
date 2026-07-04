// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_api_samples/widgets/key/global_key.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Shows two slots and a Move button', (WidgetTester tester) async {
    await tester.pumpWidget(const example.GlobalKeyExampleApp());

    expect(find.text('Slot A'), findsOneWidget);
    expect(find.text('Slot B'), findsOneWidget);
    expect(find.text('Move'), findsOneWidget);
    expect(find.byType(example.RandomColor), findsOneWidget);
  });

  testWidgets('State is preserved when widget is reparented', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildApp(useGlobalKey: true));

    final example.RandomColorState stateBefore = tester.state(
      find.byType(example.RandomColor),
    );

    await tester.tap(find.text('Move'));
    await tester.pump();

    final example.RandomColorState stateAfter = tester.state(
      find.byType(example.RandomColor),
    );

    // GlobalKey reparents the existing element — same State object, same color.
    expect(identical(stateBefore, stateAfter), isTrue);
    expect(stateAfter.color, stateBefore.color);
  });

  testWidgets('State is lost when widget is reparented without GlobalKey', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildApp(useGlobalKey: false));

    final example.RandomColorState stateBefore = tester.state(
      find.byType(example.RandomColor),
    );
    final Color colorBefore = stateBefore.color;

    await tester.tap(find.text('Move'));
    await tester.pump();

    final example.RandomColorState stateAfter = tester.state(
      find.byType(example.RandomColor),
    );

    // No key: Flutter creates a fresh element and calls initState again.
    expect(identical(stateBefore, stateAfter), isFalse);
    expect(stateAfter.color, isNot(colorBefore));
  });
}

Widget _buildApp({required bool useGlobalKey}) {
  return WidgetsApp(
    color: const Color(0xFFFFFFFF),
    builder: (BuildContext context, Widget? navigator) {
      return example.GlobalKeyExample(useGlobalKey: useGlobalKey);
    },
  );
}
