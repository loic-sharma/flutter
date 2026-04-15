// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/src/widgets/native_editable_text_web.dart';
import 'package:flutter/widgets.dart';

class NativeTextField extends StatefulWidget {
  const NativeTextField({
    super.key,
    this.focusNode,
  });

  final FocusNode? focusNode;

  @override
  State<NativeTextField> createState() => _NativeTextFieldState();
}

class _NativeTextFieldState extends State<NativeTextField> {
  FocusNode? _focusNode;
  FocusNode get _effectiveFocusNode => widget.focusNode ?? (_focusNode ??= FocusNode());

  @override
  void dispose() {
    _focusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return NativeEditableTextWeb(
        showCursor: true,
        hasFocus: _effectiveFocusNode.hasFocus,
        maxLines: maxLines,
        expands: expands,
        textAlign: textAlign,
        textDirection: textDirection,
        clipBehavior: clipBehavior,
        onFocused: onFocused,
        clientId: clientId,
        performAction: performAction,
        textInputConfiguration: textInputConfiguration,
        scrollTop: scrollTop,
        scrollLeft: scrollLeft,
        textEditingValue: textEditingValue,
        updateEditingValue: updateEditingValue,
      );
    } else {}
  }
}
