// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/src/gestures/recognizer.dart';
import 'package:flutter/src/rendering/editable.dart';
import 'package:flutter/src/scheduler/ticker.dart';
import 'package:flutter/src/services/autofill.dart';
import 'package:flutter/src/services/spell_check.dart';
import 'package:flutter/src/services/text_formatter.dart';
import 'package:flutter/src/services/text_input.dart';
import 'package:flutter/widgets.dart';

import 'editable_text.dart';

class EditableTextWeb extends EditableText {
  EditableTextWeb({
    super.key,
    required super.controller,
    required super.focusNode,
    super.readOnly = false,
    super.obscuringCharacter = '•',
    super.obscureText = false,
    super.autocorrect,
    super.smartDashesType,
    super.smartQuotesType,
    super.enableSuggestions = true,
    required super.style,
    super.strutStyle,
    required super.cursorColor,
    required super.backgroundCursorColor,
    super.textAlign = TextAlign.start,
    super.textDirection,
    super.locale,
    @Deprecated(
      'Use textScaler instead. '
      'Use of textScaleFactor was deprecated in preparation for the upcoming nonlinear text scaling support. '
      'This feature was deprecated after v3.12.0-2.0.pre.',
    )
    super.textScaleFactor,
    super.textScaler,
    super.maxLines = 1,
    super.minLines,
    super.expands = false,
    super.forceLine = true,
    super.textHeightBehavior,
    super.textWidthBasis = TextWidthBasis.parent,
    super.autofocus = false,
    super.showCursor,
    super.showSelectionHandles = false,
    super.selectionColor,
    super.selectionControls,
    super.keyboardType,
    super.textInputAction,
    super.textCapitalization = TextCapitalization.none,
    super.onChanged,
    super.onEditingComplete,
    super.onSubmitted,
    super.onAppPrivateCommand,
    super.onSelectionChanged,
    super.onSelectionHandleTapped,
    super.groupId = EditableText,
    super.onTapOutside,
    super.onTapUpOutside,
    super.inputFormatters,
    super.mouseCursor,
    super.rendererIgnoresPointer = false,
    super.cursorWidth = 2.0,
    super.cursorHeight,
    super.cursorRadius,
    super.cursorOpacityAnimates = false,
    super.cursorOffset,
    super.paintCursorAboveText = false,
    super.selectionHeightStyle,
    super.selectionWidthStyle,
    super.scrollPadding = const EdgeInsets.all(20.0),
    super.keyboardAppearance = Brightness.light,
    super.dragStartBehavior = DragStartBehavior.start,
    bool? enableInteractiveSelection,
    bool? selectAllOnFocus,
    super.scrollController,
    super.scrollPhysics,
    super.autocorrectionTextRectColor,
    @Deprecated(
      'Use `contextMenuBuilder` instead. '
      'This feature was deprecated after v3.3.0-0.5.pre.',
    )
    ToolbarOptions? toolbarOptions,
    super.autofillHints = const <String>[],
    super.autofillClient,
    super.clipBehavior = Clip.hardEdge,
    super.restorationId,
    super.scrollBehavior,
    @Deprecated(
      'Use `stylusHandwritingEnabled` instead. '
      'This feature was deprecated after v3.27.0-0.2.pre.',
    )
    super.scribbleEnabled = true,
    super.stylusHandwritingEnabled = EditableText.defaultStylusHandwritingEnabled,
    super.enableIMEPersonalizedLearning = true,
    super.contentInsertionConfiguration,
    super.contextMenuBuilder,
    super.spellCheckConfiguration,
    super.magnifierConfiguration = TextMagnifierConfiguration.disabled,
    super.undoController,
    super.hintLocales,
  });

  // TODO: This mirrors EditableText._userSelectionEnabled.
  bool get _userSelectionEnabled => enableInteractiveSelection && (!readOnly || !obscureText);

  @override
  EditableTextStateWeb createState() => EditableTextStateWeb();
}

class EditableTextStateWeb extends State<EditableText>
    with
        AutomaticKeepAliveClientMixin<EditableText>,
        WidgetsBindingObserver
    implements EditableTextState {

  bool get _hasFocus => widget.focusNode.hasFocus;
  bool get _isMultiline => widget.maxLines != 1;
  bool _didAutoFocus = false;

  // -------------------- BEGIN AUTOFILL CLIENT --------------------------------

  @override
  String get autofillId => 'EditableTextWeb-$hashCode';

  @override
  TextInputConfiguration get textInputConfiguration {
    // TODO: This is copied from EditableTextState.textInputConfiguration.
    // Find a better way to share this logic.
    // TODO: TextField and CupertinoTextField override this to add their own
    // autofill configuration.
    final List<String>? autofillHints = widget.autofillHints?.toList(growable: false);
    final AutofillConfiguration autofillConfiguration = autofillHints != null
        ? AutofillConfiguration(
            uniqueIdentifier: autofillId,
            autofillHints: autofillHints,
            currentEditingValue: currentTextEditingValue,
          )
        : AutofillConfiguration.disabled;

    _viewId = View.of(context).viewId;
    return TextInputConfiguration(
      viewId: _viewId,
      inputType: widget.keyboardType,
      readOnly: widget.readOnly,
      obscureText: widget.obscureText,
      autocorrect: widget.autocorrect,
      smartDashesType: widget.smartDashesType,
      smartQuotesType: widget.smartQuotesType,
      enableSuggestions: widget.enableSuggestions,
      enableInteractiveSelection: (widget as EditableTextWeb)._userSelectionEnabled,
      inputAction:
          widget.textInputAction ??
          (widget.keyboardType == TextInputType.multiline
              ? TextInputAction.newline
              : TextInputAction.done),
      textCapitalization: widget.textCapitalization,
      keyboardAppearance: widget.keyboardAppearance,
      autofillConfiguration: autofillConfiguration,
      enableIMEPersonalizedLearning: widget.enableIMEPersonalizedLearning,
      allowedMimeTypes: widget.contentInsertionConfiguration == null
          ? const <String>[]
          : widget.contentInsertionConfiguration!.allowedMimeTypes,
      hintLocales: widget.hintLocales,
    );
  }

  @override
  void autofill(TextEditingValue value) => updateEditingValue(value);

  int? _viewId;

  // --------------------------- END AUTOFILL CLIENT ---------------------------

  @override
  SpellCheckResults? get spellCheckResults => null;

  @override
  set spellCheckResults(SpellCheckResults? value) {
    // TODO. This is public but not referenced outside of tests.
    // Perhpas spellCheckResults should be @visibleForTesting
    assert(false);
  }

  @override
  // TODO: This disables spell check. Is that the right thing to do?
  // The web text field handles the spell check.
  SpellCheckConfiguration get spellCheckConfiguration => const SpellCheckConfiguration.disabled();

  @override
  bool get wantKeepAlive => widget.focusNode.hasFocus;

  TextEditingValue get _value => widget.controller.value;
  set _value(TextEditingValue value) {
    widget.controller.value = value;
  }

  late TextStyle _style;

  // TODO: This is only used by EditableTextState and tests.
  //Consider making this @visibleForTesting.
  @override
  void beginBatchEdit() {}

  // TODO: This is only used by EditableTextState and tests.
  //Consider making this @visibleForTesting.
  @override
  void endBatchEdit() {}

  // ------------------- BEGIN TEXT INPUT CLIENT -------------------------------
  // TODO: Should native text fields implement TextInputClient? I don't think so.

  @override
  TextEditingValue get currentTextEditingValue => _value;

  // TODO: Init state and friends set this.
  AutofillGroupState? _currentAutofillScope;
  @override
  AutofillScope? get currentAutofillScope => _currentAutofillScope;

  AutofillClient get _effectiveAutofillClient => widget.autofillClient ?? this;

  @override
  void updateEditingValue(TextEditingValue value) {
    // TODO: implement updateEditingValue
  }

  @override
  void performAction(TextInputAction action) {
    // TODO: implement performAction
  }

  @override
  void insertContent(KeyboardInsertedContent content) {
    // TODO: implement insertContent
  }

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {
    // TODO: implement performPrivateCommand
  }

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {
    // TODO: implement updateFloatingCursor
  }

  @override
  void showAutocorrectionPromptRect(int start, int end) {
    // TODO: implement showAutocorrectionPromptRect
  }

  @override
  void connectionClosed() {
    widget.focusNode.unfocus();
  }

  @override
  void didChangeInputControl(TextInputControl? oldControl, TextInputControl? newControl) {
    if (_hasFocus) {
      oldControl?.hide();
      newControl?.show();
    }
  }

  @override
  bool showToolbar() {
    return false;
  }

  @override
  void insertTextPlaceholder(Size size) {
    // TODO: implement insertTextPlaceholder
  }

  @override
  void removeTextPlaceholder() {
    // TODO: implement removeTextPlaceholder
  }

  // ------------------- END TEXT INPUT CLIENT -------------------------------

  // ------------------- BEGIN TEXT SELECTION DELEGATE -----------------------
  // TODO: Does it make sense for EditableTextStateWeb to implement TextSelectionDelegate?
  // Native text fields should not use framework text selection.
  // TextField and CupertinoTextField should likely be aware of this.
  // If we introduce an EditableTextState interface, perhaps the text selection delegate
  // would be a nullable property on the interface.

  @override
  void userUpdateTextEditingValue(TextEditingValue value, SelectionChangedCause? cause) {
    // TODO: implement userUpdateTextEditingValue
  }

  @override
  void hideToolbar([bool hideHandles = true]) {
    // TODO: implement hideToolbar
  }

  @override
  void bringIntoView(TextPosition position) {
    // TODO
    //
    // # Implementation options
    //
    // ## Option 1. Move the cursor to the specified position.
    //
    // This is not ideal since this method should only scroll the text field into view.
    //
    // ```
    // // Gemini: Most browsers will not visually update the cursor position unless the element is currently focused. Always call .focus() before setting the range.
    // input.focus();
    // input.setSelectionRange(position, position);
    // ```
    //
    // ## Option 2. Scroll the text field into view.
    //
    // Use scrollTop or scrollLeft to scroll to the desired position.
    // ```
    // input.scrollTop = position.offset;
    // ```
    //
    // This is hard since you need to know the text position's offset in the DOM.
    // You can use a hidden <div> to measure the text and calculate the text position's
    // offset.
    //
    // ## Option 3. Do nothing?
    //
    // What breaks?
    //
    // # Uses
    // This is used to:
    // 1. After accepting a spell check suggestion in Cupertino / Material.
    // 2. After TextField long press selection change.
    // 3. After SelectableText long press selection change.
    // 4. After EditableText selection changes.
  }

  @override
  bool get cutEnabled => !widget.readOnly && !widget.obscureText && !textEditingValue.selection.isCollapsed;

  @override
  bool get copyEnabled => !widget.obscureText && !textEditingValue.selection.isCollapsed;

  @override
  bool get pasteEnabled => !widget.readOnly;

  @override
  bool get selectAllEnabled {
    if (!widget.enableInteractiveSelection || (widget.readOnly && widget.obscureText)) {
      return false;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.macOS:
        return false;
      case TargetPlatform.iOS:
        return textEditingValue.text.isNotEmpty && textEditingValue.selection.isCollapsed;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return textEditingValue.text.isNotEmpty &&
            !(textEditingValue.selection.start == 0 &&
                textEditingValue.selection.end == textEditingValue.text.length);
    }
  }

  @override
  bool get lookUpEnabled {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return false;
    }
    return !widget.obscureText &&
        !textEditingValue.selection.isCollapsed &&
        textEditingValue.selection.textInside(textEditingValue.text).trim() != '';
  }

  @override
  bool get searchWebEnabled {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return false;
    }

    return !widget.obscureText &&
        !textEditingValue.selection.isCollapsed &&
        textEditingValue.selection.textInside(textEditingValue.text).trim() != '';
  }

  @override
  bool get shareEnabled {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return !widget.obscureText &&
            !textEditingValue.selection.isCollapsed &&
            textEditingValue.selection.textInside(textEditingValue.text).trim() != '';
      case TargetPlatform.macOS:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return false;
    }
  }

  @override
  bool get liveTextInputEnabled => false;

  @override
  void cutSelection(SelectionChangedCause cause) {
    // TODO: implement cutSelection
  }

  @override
  Future<void> pasteText(SelectionChangedCause cause) {
    // TODO: implement pasteText
    throw UnimplementedError();
  }

  @override
  void selectAll(SelectionChangedCause cause) {
    // TODO: implement selectAll
  }

  @override
  void copySelection(SelectionChangedCause cause) {
    // TODO: implement copySelection
  }

  @override
  void performSelector(String selectorName) {
    // TODO: implement performSelector
  }

  // ------------------- END TEXT SELECTION DELEGATE ---------------------------

  @override
  Future<void> lookUpSelection(SelectionChangedCause cause) {
    // TODO: This is only used by EditableTextState.
    // Consider making this private or @visibleForTesting.
    // It seems like this should be on TextSelectionDelegate though?
    throw UnimplementedError();
  }

  @override
  Future<void> searchWebForSelection(SelectionChangedCause cause) {
    // TODO: This is only used by EditableTextState.
    // Consider making this private or @visibleForTesting.
    // It seems like this should be on TextSelectionDelegate though?
    // TODO: System channel SearchWeb.invoke not implemented for web.
    return Future<void>.value();
  }

  @override
  Future<void> shareSelection(SelectionChangedCause cause) {
    // TODO: This is only used by EditableTextState.
    // Consider making this private or @visibleForTesting.
    // It seems like this should be on TextSelectionDelegate though?
    // TODO. System channel Share.invoke not implemented for web.
    return Future<void>.value();
  }

  @override
  void showMagnifier(Offset positionToShow) {
    // TODO: This is used by TextSelectionGestureDetectorBuilder.
    // Perhaps this could be moved to TextSelectionDelegate?
  }

  @override
  void hideMagnifier() {
    // TODO: This is used by TextSelectionGestureDetectorBuilder.
    // Perhaps this could be moved to TextSelectionDelegate?
  }

  @override
  bool showSpellCheckSuggestionsToolbar() {
    // Used by TextSelectionGestureDetectorBuilder.onSingleTapUp
    // Perhaps this could be moved to TextSelectionDelegate?
    return false;
  }

  // TODO: This is only used by EditableTextState.
  // Consider making this private or @visibleForTesting.
  // This is also deprecated so maybe we should remove it.
  @override
  List<ContextMenuButtonItem>? buttonItemsForToolbarOptions([TargetPlatform? targetPlatform]) {
    return null;
  }

  @override
  ClipboardStatusNotifier get clipboardStatus => _WebClipboardStatusNotifier._instance;

  // This is used by spell check suggestions toolbar, adaptive text selection toolbar.
  @override
  TextSelectionToolbarAnchors get contextMenuAnchors => const TextSelectionToolbarAnchors(primaryAnchor: Offset.zero, secondaryAnchor: Offset.zero);

  // This is used by adaptive text selection toolbar.
  @override
  List<ContextMenuButtonItem> get contextMenuButtonItems => const <ContextMenuButtonItem>[];

  // Is there a better way to do this?
  // This indicates we want to add an interface for EditableTextState that doesn't expose this stuff...
  @override
  Ticker createTicker(TickerCallback onTick) => throw UnimplementedError();

  @override
  @visibleForTesting
  Duration get cursorBlinkInterval => Duration.zero;

  @override
  @visibleForTesting
  bool get cursorCurrentlyVisible => false;

  @override
  @visibleForTesting
  TextSelectionOverlay? get selectionOverlay => null;

  @override
  void didChangeMetrics() {
    // EditableTextState.didChangeMetrics:
    // 1. Updates the text selection overlay for scroll
    // 2. Shows caret on screen.
  }

  @override
  SuggestionSpan? findSuggestionSpanAtCursorIndex(int cursorIndex) {
    // Used by:
    // 1. Spell check suggestions toolbar
    // 2. TextSelectionGestureDetectorBuilder
    return null;
  }

  @override
  ({double endGlyphHeight, double startGlyphHeight}) getGlyphHeights() {
    // Used by SystemContextMenu.
    return (endGlyphHeight: 0, startGlyphHeight: 0);
  }

  @override
  // Used by:
  // 1. SystemContextMenu
  // 2. TextSelectionGestureDetectorBuilder
  RenderEditable get renderEditable => throw UnimplementedError();

  @override
  void requestKeyboard() {
    // Used by:
    // 1. TestWidgetsFlutterBinding to set current focused editable
    // 2. TextSelectionGestureDetectorBuilder
    // 3. TextField
    // 4. CupertinoTextField
    widget.focusNode.requestFocus();
  }

  // TODO: This is only used by EditableTextState.
  // Consider making this private or @visibleForTesting.
  @override
  bool get spellCheckEnabled => false;

  @override
  TextEditingValue get textEditingValue => _value;

  @override
  void toggleToolbar([bool hideHandles = true]) {
    // Used by:
    // 1. Selectable text
    // 2. TextField (_TextFieldState._handleSelectionHandleTapped)
    // 3. TextSelectionGestureDetectorBuilder.onSingleTapUp
    // 4. TextSelectionGestureDetectorBuilder.onSecondaryTap
    // TODO: Perhaps this should be moved to TextSelectionDelegate?
  }

  void _handleFocusChanged() {
    updateKeepAlive();
  }

  @override
  TextSpan buildTextSpan() {
    // TODO: EditableText.buildTextSpan is public so that a descendant can override it
    // to customize the appearance of the text. If we create a EditableTextState interface,
    // I'd consider not adding this method to it.
    assert(false);
    throw UnimplementedError();
  }

  // -------------------------- BEGIN STATE LIFECYCLE --------------------------

  @protected
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocusChanged);
  }

  @protected
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _style = MediaQuery.boldTextOf(context)
        ? widget.style.merge(const TextStyle(fontWeight: FontWeight.bold))
        : widget.style;

    final AutofillGroupState? newAutofillGroup = AutofillGroup.maybeOf(context);
    if (currentAutofillScope != newAutofillGroup) {
      _currentAutofillScope?.unregister(autofillId);
      _currentAutofillScope = newAutofillGroup;
      _currentAutofillScope?.register(_effectiveAutofillClient);
    }

    if (!_didAutoFocus && widget.autofocus) {
      _didAutoFocus = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          FocusScope.of(context).autofocus(widget.focusNode);
        }
      }, debugLabel: 'EditableTextWeb.autofocus');
    }
  }

  @protected
  @override
  void didUpdateWidget(EditableText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autofillClient != oldWidget.autofillClient) {
      _currentAutofillScope?.unregister(oldWidget.autofillClient?.autofillId ?? autofillId);
      _currentAutofillScope?.register(_effectiveAutofillClient);
    }

    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChanged);
      widget.focusNode.addListener(_handleFocusChanged);
      updateKeepAlive();
    }

    if (widget.style != oldWidget.style) {
      // The _textInputConnection will pick up the new style when it attaches in
      // _openInputConnection.
      _style = MediaQuery.boldTextOf(context)
          ? widget.style.merge(const TextStyle(fontWeight: FontWeight.bold))
          : widget.style;
    }
  }

  @protected
  @override
  void dispose() {
    _currentAutofillScope?.unregister(autofillId);
    widget.focusNode.removeListener(_handleFocusChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    super.build(context); // See AutomaticKeepAliveClientMixin.

    final double devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final TextDirection textDirection = widget.textDirection ?? Directionality.of(context);
    final TextScaler textScaler = switch ((widget.textScaler, widget.textScaleFactor)) {
      (final TextScaler textScaler, _) => textScaler,
      (null, final double textScaleFactor) => TextScaler.linear(textScaleFactor),
      (null, null) => MediaQuery.textScalerOf(context),
    };

    return _TODOHackRemoveMeSuppressTextSelectionGestures(
      child: ListenableBuilder(
        listenable: Listenable.merge([widget.focusNode, widget.controller]),
        builder: (context, child) {
          return _EditableWeb(
            textStyle: _style,
            cursorColor: widget.cursorColor,
            showCursor: widget.showCursor,
            forceLine: widget.forceLine,
            hasFocus: widget.focusNode.hasFocus,
            maxLines: widget.maxLines,
            minLines: widget.minLines,
            expands: widget.expands,
            selectionColor: widget.selectionColor,
            textScaler: textScaler,
            textAlign: widget.textAlign,
            textDirection: textDirection,
            locale: widget.locale,
            // offset: widget.offset,
            rendererIgnoresPointer: widget.rendererIgnoresPointer,
            devicePixelRatio: devicePixelRatio,
            clipBehavior: widget.clipBehavior,
            requestKeyboard: requestKeyboard,
            clientId: 123, // TODO: Do we still need this?
            performAction: performAction,
            textInputConfiguration: textInputConfiguration,
            currentAutofillScope: currentAutofillScope,
            scrollTop: 0, // TODO
            scrollLeft: 0, // TODO
            textEditingValue: widget.controller.text,
            updateEditingValue: updateEditingValue,
          );
        },
      ),
    );
  }

  // --------------------------- END STATE LIFECYCLE ---------------------------
}

// class RenderEditableWeb extends RenderBox
//     with
//         RelayoutWhenSystemFontsChangeMixin,
//         ContainerRenderObjectMixin<RenderBox, TextParentData>,
//         RenderInlineChildrenContainerDefaults
//     implements RenderEditable {
// }

class _TODOHackRemoveMeSuppressTextSelectionGestures extends StatelessWidget {
  const _TODOHackRemoveMeSuppressTextSelectionGestures({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TextSelectionGestureDetector(
        onTapTrackStart: () {},
        onTapTrackReset: () {},
        onTapDown: (TapDragDownDetails a) {},
        onForcePressStart: (ForcePressDetails a) {},
        onForcePressEnd: (ForcePressDetails a) {},
        onSecondaryTap: () {},
        onSecondaryTapDown: (TapDownDetails a) {},
        onSingleTapUp: (TapDragUpDetails a) {},
        onSingleTapCancel: () {},
        onUserTap: () {},
        onSingleLongTapStart: (LongPressStartDetails a) {},
        onSingleLongTapMoveUpdate: (LongPressMoveUpdateDetails a) {},
        onSingleLongTapEnd: (LongPressEndDetails a) {},
        onDoubleTapDown: (TapDragDownDetails a) {},
        onTripleTapDown: (TapDragDownDetails a) {},
        onDragSelectionStart: (TapDragStartDetails a) {},
        onDragSelectionUpdate: (TapDragUpdateDetails a) {},
        onDragSelectionEnd: (TapDragEndDetails a) {},
        behavior: HitTestBehavior.opaque,
        child: child,
      );
  }
}

/// A [ClipboardStatusNotifier] whose [value] is hardcoded to
/// [ClipboardStatus.pasteable].
///
/// Useful to avoid showing a permission dialog on web, which happens when
/// [Clipboard.hasStrings] is called.
class _WebClipboardStatusNotifier extends ClipboardStatusNotifier {
  _WebClipboardStatusNotifier._();

  static final _WebClipboardStatusNotifier _instance = _WebClipboardStatusNotifier._();

  @override
  ClipboardStatus value = ClipboardStatus.pasteable;

  @override
  Future<void> update() => Future<void>.value();
}

class _EditableWeb extends StatefulWidget {
  const _EditableWeb({
    super.key,
    this.textStyle,
    required this.cursorColor,
    required this.showCursor,
    required this.forceLine,
    required this.hasFocus,
    required this.maxLines,
    this.minLines,
    required this.expands,
    this.selectionColor,
    required this.textScaler,
    required this.textAlign,
    required this.textDirection,
    this.locale,
    // required this.offset,
    this.rendererIgnoresPointer = false,
    required this.devicePixelRatio,
    required this.clipBehavior,
    required this.requestKeyboard,
    required this.clientId,
    required this.performAction,
    required this.textInputConfiguration, // contains a bunch of things like obscureText, readOnly, autofillHints, etc.
    this.currentAutofillScope, // contains a bunch of things like obscureText, readOnly, autofillHints, etc.
    required this.scrollTop,
    required this.scrollLeft,
    required this.textEditingValue,
    required this.updateEditingValue,
  });

  final TextStyle? textStyle;
  final Color cursorColor;
  final bool showCursor;
  final bool forceLine;
  final bool hasFocus;
  final int? maxLines;
  final int? minLines;
  final bool expands;
  final Color? selectionColor;
  final TextScaler textScaler;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final Locale? locale;
  // final ViewportOffset offset;
  final bool rendererIgnoresPointer;
  final double devicePixelRatio;
  final Clip clipBehavior;
  final void Function() requestKeyboard;
  final int clientId;
  final void Function(TextInputAction) performAction;
  final TextInputConfiguration textInputConfiguration;
  final AutofillScope? currentAutofillScope;
  final double scrollTop;
  final double scrollLeft;
  final String textEditingValue;
  final void Function(TextEditingValue) updateEditingValue;

  @override
  State<_EditableWeb> createState() => _EditableWebState();
}

class _EditableWebState extends State<_EditableWeb> {
  late html.HtmlElement _inputEl;
  html.InputElement? _inputElement;
  html.TextAreaElement? _textAreaElement;
  double sizedBoxHeight = 24;
  late final int _maxLines;
  TextEditingValue? lastEditingState;
  bool get _isMultiline => widget.maxLines != 1;

  @override
  void initState() {
    super.initState();
    _maxLines = widget.maxLines ?? 1;
  }

  String colorToCss(Color color) {
    // hard coding opacity to 1 for now because EditableText passes cursorColor with 0 opacity.
    return 'rgba(${color.red}, ${color.green}, ${color.blue}, ${color.opacity == 0 ? 1 : color.opacity})';
  }

  String textStyleToCss(TextStyle style) {
    final List<String> cssProperties = <String>[];

    if (style.color != null) {
      cssProperties.add('color: ${colorToCss(style.color!)}');
    }

    if (style.fontSize != null) {
      cssProperties.add('font-size: ${style.fontSize}px');
    }

    if (style.fontWeight != null) {
      cssProperties.add('font-weight: ${style.fontWeight!.value}');
    }

    if (style.fontStyle != null) {
      cssProperties.add(
          'font-style: ${style.fontStyle == FontStyle.italic ? 'italic' : 'normal'}');
    }

    if (style.fontFamily != null) {
      cssProperties.add('font-family: "${style.fontFamily}"');
    }

    if (style.letterSpacing != null) {
      cssProperties.add('letter-spacing: ${style.letterSpacing}px');
    }

    if (style.wordSpacing != null) {
      cssProperties.add('word-spacing: ${style.wordSpacing}');
    }

    if (style.decoration != null) {
      final List<String> textDecorations = <String>[];
      final TextDecoration decoration = style.decoration!;

      if (decoration == TextDecoration.none) {
        textDecorations.add('none');
      } else {
        if (decoration.contains(TextDecoration.underline)) {
          textDecorations.add('underline');
        }

        if (decoration.contains(TextDecoration.underline)) {
          textDecorations.add('underline');
        }

        if (decoration.contains(TextDecoration.underline)) {
          textDecorations.add('underline');
        }
      }

      cssProperties.add('text-decoration: ${textDecorations.join(' ')}');
    }

    return cssProperties.join('; ');
  }

  /// NOTE: Taken from engine
  /// TODO: make more functional, set autocap attr outside of function using return val
  /// Sets `autocapitalize` attribute on input elements.
  ///
  /// This attribute is only available for mobile browsers.
  ///
  /// Note that in mobile browsers the onscreen keyboards provide sentence
  /// level capitalization as default as apposed to no capitalization on desktop
  /// browser.
  ///
  /// See: https://developers.google.com/web/updates/2015/04/autocapitalize
  /// https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/autocapitalize
  void setAutocapitalizeAttribute(html.HtmlElement inputEl) {
    String autocapitalize = '';
    switch (widget.textInputConfiguration.textCapitalization) {
      case TextCapitalization.words:
        // TODO(mdebbar): There is a bug for `words` level capitalization in IOS now.
        // For now go back to default. Remove the check after bug is resolved.
        // https://bugs.webkit.org/show_bug.cgi?id=148504
        // TODO add browser engines
        // if (browserEngine == BrowserEngine.webkit) {
        //   autocapitalize = 'sentences';
        // } else {
        //   autocapitalize = 'words';
        // }
        autocapitalize = 'words';
      case TextCapitalization.characters:
        autocapitalize = 'characters';
      case TextCapitalization.sentences:
        autocapitalize = 'sentences';
      case TextCapitalization.none:
      default:
        autocapitalize = 'off';
        break;
    }
    inputEl.setAttribute('autocapitalize', autocapitalize);
    // inputEl.autocapitalize = autocapitalize;
  }

  /// NOTE: Taken from engine.
  /// Converts [align] to its corresponding CSS value.
  ///
  /// This value is used as the "text-align" CSS property, e.g.:
  ///
  /// ```css
  /// text-align: right;
  /// ```
  String textAlignToCssValue(
      ui.TextAlign? align, ui.TextDirection textDirection) {
    switch (align) {
      case ui.TextAlign.left:
        return 'left';
      case ui.TextAlign.right:
        return 'right';
      case ui.TextAlign.center:
        return 'center';
      case ui.TextAlign.justify:
        return 'justify';
      case ui.TextAlign.end:
        switch (textDirection) {
          case ui.TextDirection.ltr:
            return 'end';
          case ui.TextDirection.rtl:
            return 'left';
        }
      case ui.TextAlign.start:
        switch (textDirection) {
          case ui.TextDirection.ltr:
            return ''; // it's the default
          case ui.TextDirection.rtl:
            return 'right';
        }
      case null:
        // If align is not specified return default.
        return '';
    }
  }

  /// Takes a font size read from the style property (e.g. '16px) and scales it
  /// by some factor. Returns the scaled font size in a CSS friendly format.
  /// TODO
  // String scaleFontSize(String fontSize, double textScaleFactor) {
  //   assert(fontSize.endsWith('px'));
  //   final String strippedFontSize = fontSize.replaceAll('px', '');
  //   final double parsedFontSize = double.parse(strippedFontSize);
  //   final int scaledFontSize = (parsedFontSize * textScaleFactor).round();

  //   return '${scaledFontSize}px';
  // }

  Map<String, String> getKeyboardTypeAttributes(TextInputType inputType) {
    final bool isDecimal = inputType.decimal ?? false; // appropriate default?

    switch (inputType) {
      case TextInputType.number:
        return <String, String>{
          'type': 'number',
          'inputmode': isDecimal ? 'decimal' : 'numeric'
        };
      case TextInputType.phone:
        return <String, String>{'type': 'tel', 'inputmode': 'tel'};
      case TextInputType.emailAddress:
        return <String, String>{'type': 'email', 'inputmode': 'email'};
      case TextInputType.url:
        return <String, String>{'type': 'url', 'inputmode': 'url'};
      case TextInputType.none:
        return <String, String>{'type': 'text', 'inputmode': 'none'};
      case TextInputType.text:
        return <String, String>{'type': 'text', 'inputmode': 'text'};
      default:
        return <String, String>{'type': 'text', 'inputmode': 'text'};
    }
  }

  String? getEnterKeyHint(TextInputAction inputAction) {
    switch (inputAction) {
      case TextInputAction.continueAction:
      case TextInputAction.next:
        return 'next';
      case TextInputAction.previous:
        return 'previous';
      case TextInputAction.done:
        return 'done';
      case TextInputAction.go:
        return 'go';
      case TextInputAction.newline:
        return 'enter';
      case TextInputAction.search:
        return 'search';
      case TextInputAction.send:
        return 'send';
      case TextInputAction.emergencyCall:
      case TextInputAction.join:
      case TextInputAction.none:
      case TextInputAction.route:
      case TextInputAction.unspecified:
      default:
        return null;
    }
  }

  String _getAutocompleteAttribute(String autofillHint) {
    switch (autofillHint) {
      case AutofillHints.birthday:
        return 'bday';
      case AutofillHints.birthdayDay:
        return 'bday-day';
      case AutofillHints.birthdayMonth:
        return 'bday-month';
      case AutofillHints.birthdayYear:
        return 'bday-year';
      case AutofillHints.countryCode:
        return 'country';
      case AutofillHints.countryName:
        return 'country-name';
      case AutofillHints.creditCardExpirationDate:
        return 'cc-exp';
      case AutofillHints.creditCardExpirationMonth:
        return 'cc-exp-month';
      case AutofillHints.creditCardExpirationYear:
        return 'cc-exp-year';
      case AutofillHints.creditCardFamilyName:
        return 'cc-family-name';
      case AutofillHints.creditCardGivenName:
        return 'cc-given-name';
      case AutofillHints.creditCardMiddleName:
        return 'cc-additional-name';
      case AutofillHints.creditCardName:
        return 'cc-name';
      case AutofillHints.creditCardNumber:
        return 'cc-number';
      case AutofillHints.creditCardSecurityCode:
        return 'cc-csc';
      case AutofillHints.creditCardType:
        return 'cc-type';
      case AutofillHints.email:
        return 'email';
      case AutofillHints.familyName:
        return 'family-name';
      case AutofillHints.fullStreetAddress:
        return 'street-address';
      case AutofillHints.gender:
        return 'sex';
      case AutofillHints.givenName:
        return 'given-name';
      case AutofillHints.impp:
        return 'impp';
      case AutofillHints.jobTitle:
        return 'organization-title';
      case AutofillHints.middleName:
        return 'middleName';
      case AutofillHints.name:
        return 'name';
      case AutofillHints.namePrefix:
        return 'honorific-prefix';
      case AutofillHints.nameSuffix:
        return 'honorific-suffix';
      case AutofillHints.newPassword:
        return 'new-password';
      case AutofillHints.nickname:
        return 'nickname';
      case AutofillHints.oneTimeCode:
        return 'one-time-code';
      case AutofillHints.organizationName:
        return 'organization';
      case AutofillHints.password:
        return 'current-password';
      case AutofillHints.photo:
        return 'photo';
      case AutofillHints.postalCode:
        return 'postal-code';
      case AutofillHints.streetAddressLevel1:
        return 'address-level1';
      case AutofillHints.streetAddressLevel2:
        return 'address-level2';
      case AutofillHints.streetAddressLevel3:
        return 'address-level3';
      case AutofillHints.streetAddressLevel4:
        return 'address-level4';
      case AutofillHints.streetAddressLine1:
        return 'address-line1';
      case AutofillHints.streetAddressLine2:
        return 'address-line2';
      case AutofillHints.streetAddressLine3:
        return 'address-line3';
      case AutofillHints.telephoneNumber:
        return 'tel';
      case AutofillHints.telephoneNumberAreaCode:
        return 'tel-area-code';
      case AutofillHints.telephoneNumberCountryCode:
        return 'tel-country-code';
      case AutofillHints.telephoneNumberExtension:
        return 'tel-extension';
      case AutofillHints.telephoneNumberLocal:
        return 'tel-local';
      case AutofillHints.telephoneNumberLocalPrefix:
        return 'tel-local-prefix';
      case AutofillHints.telephoneNumberLocalSuffix:
        return 'tel-local-suffix';
      case AutofillHints.telephoneNumberNational:
        return 'tel-national';
      case AutofillHints.transactionAmount:
        return 'transaction-amount';
      case AutofillHints.transactionCurrency:
        return 'transaction-currency';
      case AutofillHints.url:
        return 'url';
      case AutofillHints.username:
        return 'username';
      default:
        return autofillHint;
    }
  }

  void setElementStyles(html.HtmlElement inputEl) {
    // style based on TextStyle
    if (widget.textStyle != null) {
      inputEl.style.cssText = textStyleToCss(widget.textStyle!);
    }

    // reset input styles
    inputEl.style
      ..width = '100%'
      ..height = '100%'
      ..setProperty(
          'caret-color',
          widget.showCursor
              ? colorToCss(widget.cursorColor)
              : 'transparent')
      ..outline = 'none'
      ..border = 'none'
      ..background = 'transparent'
      ..padding = '0'
      ..overflow = 'hidden'
      ..textAlign = textAlignToCssValue(widget.textAlign, widget.textDirection)
      // ..pointerEvents = widget.rendererIgnoresPointer ? 'none' : 'auto' // Can't use this, material3 text field sets this to none
      ..direction = widget.textDirection.name
      ..lineHeight = '1.5'; // can this be modified by a property?

    // Removes autofill overlay which clashes with Flutter styles
    inputEl.classes.add('transparentTextEditing');

    // debug
    // if (widget.textInputConfiguration.obscureText) {
    //   inputEl.style.outline = '1px solid red'; // debug
    // }

    if (widget.selectionColor != null) {
      /*
        Needs the following code in engine
          sheet.insertRule('''
            $cssSelectorPrefix flt-glass-pane {
              --selection-background: #000000;
            }
          ''', sheet.cssRules.length);
          sheet.insertRule('''
            $cssSelectorPrefix .customInputSelection::selection {
              background-color: var(--selection-background);
            }
          ''', sheet.cssRules.length);
      */
      // There is no easy way to modify pseudoclasses via js. We are accomplishing this
      // here via modifying a css var that is responsible for this ::selection style
      html.document.querySelector('flt-glass-pane')!.style.setProperty(
          '--selection-background', colorToCss(widget.selectionColor!));

      // To ensure we're only modifying selection on this specific input, we attach a custom class
      // instead of adding a blanket rule for all inputs.
      inputEl.classes.add('customInputSelection');
    }
  }

  // TODO: Handle composition and delta model?
  // TODO: Clean up type stuff
  void handleChange(html.Event event) {
    if (isTextArea(_inputEl)) {
      final html.TextAreaElement element = _inputEl as html.TextAreaElement;
      final String text = element.value!;
      final TextSelection selection = TextSelection(
          baseOffset: element.selectionStart ?? 0,
          extentOffset: element.selectionEnd ?? 0);

      print('handle change value ${text}');
      print(
          'handle change selection ${element.selectionStart} - ${element.selectionEnd}');
      final TextEditingValue newEditingState =
          TextEditingValue(text: text, selection: selection);

      if (newEditingState != lastEditingState) {
        lastEditingState = newEditingState;
        print('updateEditingState');
        updateEditingState(newEditingState);
      }
    } else if(isInput(_inputEl)) {
      final html.InputElement element = _inputEl as html.InputElement;
      final String text = element.value!;
      final TextSelection selection = TextSelection(
          baseOffset: element.selectionStart ?? 0,
          extentOffset: element.selectionEnd ?? 0);

      print('handle change value ${text}');
      print(
          'handle change selection ${element.selectionStart} - ${element.selectionEnd}');
      final TextEditingValue newEditingState =
          TextEditingValue(text: text, selection: selection);

      if (newEditingState != lastEditingState) {
        lastEditingState = newEditingState;
        print('updateEditingState');
        updateEditingState(newEditingState);
      }
    }
  }

  void setElementListeners(html.HtmlElement inputEl) {
    // listen for events
    inputEl.onInput.listen((html.Event e) {
      handleChange(e);
    });

    inputEl.onFocus.listen((html.Event e) {
      widget.requestKeyboard();

      if (widget.selectionColor != null) {
        // Since we're relying on a CSS variable to handle selection background, we
        // run into an issue when there are multiple inputs with multiple selection background
        // values. In that case, the variable is always set to whatever the last rendered input's selection
        // background value was set to.  To fix this, we update that CSS variable to the currently focused
        // element's selection color value.
        inputEl.classes.add('customInputSelection');
        html.document.querySelector('flt-glass-pane')!.style.setProperty(
            '--selection-background', colorToCss(widget.selectionColor!));
      }
    });

    inputEl.onKeyDown.listen((html.KeyboardEvent event) {
      maybeSendAction(event);
    });

    // Prevent default for mouse events to prevent selection interference/flickering.
    // We want to let the framework handle these pointerevents.
    // NEW 10/10 - we actually want the browser to handle these.
    // inputEl.onMouseDown.listen((html.MouseEvent event) {
    //   event.preventDefault();
    // });

    // inputEl.onMouseUp.listen((html.MouseEvent event) {
    //   event.preventDefault();
    // });

    // inputEl.onMouseMove.listen((html.MouseEvent event) {
    //   event.preventDefault();
    // });
  }

  void setGeneralAttributes(html.HtmlElement inputEl) {
    // calculate box size based on specified lines
    // TODO: can we make this better?
    sizedBoxHeight *= _maxLines;

    setAutocapitalizeAttribute(inputEl);

    inputEl.setAttribute('autocorrect',
        widget.textInputConfiguration.autocorrect ? 'on' : 'off');

    final String? enterKeyHint =
        getEnterKeyHint(widget.textInputConfiguration.inputAction);

    if (enterKeyHint != null) {
      inputEl.setAttribute('enterkeyhint', enterKeyHint);
    }
  }

  void setInputElementAttributes(html.InputElement inputEl) {
    // set attributes
    inputEl.value = widget.textEditingValue;
    inputEl.readOnly = widget.textInputConfiguration.readOnly;

    if (widget.textInputConfiguration.obscureText) {
      inputEl.type = 'password';
    } else {
      final Map<String, String> attributes =
          getKeyboardTypeAttributes(widget.textInputConfiguration.inputType);
      inputEl.type = attributes['type'];
      inputEl.inputMode = attributes['inputmode'];
    }

    if (widget.textInputConfiguration.autofillConfiguration.autofillHints
        .isNotEmpty) {
      // browsers can only use one autocomplete attribute
      final String autocomplete = _getAutocompleteAttribute(widget
          .textInputConfiguration.autofillConfiguration.autofillHints.first);
      inputEl.id = autocomplete;
      inputEl.name = autocomplete;
      inputEl.autocomplete = autocomplete;
    }

    _inputElement = inputEl;
  }

  void setTextAreaElementAttributes(html.TextAreaElement textAreaEl) {
    textAreaEl.value = widget.textEditingValue;
    textAreaEl.rows = _maxLines;
    textAreaEl.readOnly = widget.textInputConfiguration.readOnly;
    _textAreaElement = textAreaEl;
  }

  // TODO add a submit type input to each autofill group
  void setupAutofill(html.HtmlElement inputEl) {
    // No autofill group, nothing to setup
    if (widget.currentAutofillScope == null) {
      return;
    }

    // Create a unique id for the form id and form attribute
    // Taken from engine.
    final Iterable<AutofillClient> autofillClients =
        widget.currentAutofillScope!.autofillClients;
    final List<String> ids = List<String>.empty(growable: true);

    for (final AutofillClient autofillClient in autofillClients) {
      ids.add(autofillClient.autofillId);
    }

    ids.sort();
    final StringBuffer idBuffer = StringBuffer();

    // Add a separator between element identifiers.
    for (final String id in ids) {
      if (idBuffer.length > 0) {
        idBuffer.write('*');
      }
      idBuffer.write(id);
    }

    final String formId = idBuffer.toString();

    // Only create form if it doesn't already exist.
    if (html.document.getElementById(formId) == null) {
      final html.FormElement formElement = html.FormElement();
      formElement.id = formId;

      // Append the form to the glasspane
      html.document.querySelector('flt-glass-pane')!.append(formElement);
    }

    final String autofillId =
        widget.textInputConfiguration.autofillConfiguration.uniqueIdentifier;

    // verify the current element is inside the autofill group.
    if (widget.currentAutofillScope?.getAutofillClient(autofillId) != null) {
      // associate with created form using form attribute and formId.
      inputEl.setAttribute('form', formId);
    }
  }

  void initializePlatformView(html.HtmlElement inputEl) {
    _isMultiline
        ? setTextAreaElementAttributes(inputEl as html.TextAreaElement)
        : setInputElementAttributes(inputEl as html.InputElement);
    setElementStyles(inputEl);
    setElementListeners(inputEl);
    setGeneralAttributes(inputEl);
    setupAutofill(inputEl);

    _inputEl = inputEl;
  }

  /* Incoming methods (back to framework)
    - TextInputClient.updateEditingState -> send new editing state
    -- right now, this calls _updateEditingValue (on TextInput instance), which calls
    -- updateEditingValue (on the TextInputClient, which is EditableText).
    - TextInputClient.updateEditingStateWithTag - ?
    - TextInputClient.performAction ->
    - TextInputClient.requestExistingInputState
    - TextInputClient.onConnectionClosed
  */
  void updateEditingState(TextEditingValue value) {
    // todo: we replaced TextInput.updateEditingValue - this wrapper is probably redundant
    widget.updateEditingValue(value);
  }

  void updateEditingStateWithTag() {
    // autofill stuff?
  }

  void performAction(TextInputAction action) {
    widget.performAction(action);
  }

  void requestExistingInputState() {
    // no-op
  }

  void onConnectionClosed() {
    // no-op?
  }

  void maybeSendAction(html.KeyboardEvent event) {
    if (event.keyCode == html.KeyCode.ENTER) {
      performAction(widget.textInputConfiguration.inputAction);

      // Prevent the browser from inserting a new line when it's not a multiline input.
      // note: taken from engine. Do we still need?
      if (widget.textInputConfiguration.inputType != TextInputType.multiline) {
        event.preventDefault();
      }
    }
  }

  @override
  void didUpdateWidget(_EditableWeb oldWidget) {
    super.didUpdateWidget(oldWidget);

    /*
      should we listen to the hasFocus attribute? Focus seems fine for now.
    */

    // we do this because widget can sometimes selectionColor can be passed
    // as conditionally null depending on some state that's determined in a layer
    // above (e.g. `hasFocus`), so we need to keep track of the selectionColor
    // and set it when appropriate.
    if (widget.selectionColor != oldWidget.selectionColor) {
      if (widget.selectionColor != null) {
        html.document.querySelector('flt-glass-pane')!.style.setProperty(
            '--selection-background', colorToCss(widget.selectionColor!));
        _inputEl.classes.add('customInputSelection');
      }
    }
  }

  // single EditableWeb that is a form owner for both cases.
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: sizedBoxHeight,
      child: ExcludeFocus(
        child: HtmlElementView.fromTagName(
          tagName: _isMultiline ? 'textarea' : 'input',
          onElementCreated: (Object element) {
            initializePlatformView(element as html.HtmlElement);
          },
        ),
      ),
    );
  }
}

bool isInput(html.HtmlElement el) {
  return el.tagName.toUpperCase() == 'INPUT';
}

bool isTextArea(html.HtmlElement el) {
  return el.tagName.toUpperCase() == 'TEXTAREA';
}

