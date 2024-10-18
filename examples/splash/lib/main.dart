// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

void main() {
  runApp(
    const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        FlutterLogo(size: 48),
        Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'This app is only meant to be run under the Flutter debugger',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black87),
          ),
        ),
      ],
    )
      .center()
      .decoratedBox(decoration: BoxDecoration(color: Colors.white))
      .directionality(textDirection: TextDirection.ltr),
  );
}
