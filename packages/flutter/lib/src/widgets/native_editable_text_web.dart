// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'basic.dart';
import 'focus_manager.dart';
import 'focus_scope.dart';
import 'framework.dart';
import 'layout_builder.dart';
import 'placeholder.dart';
import 'platform_view.dart';

class NativeEditableTextWeb extends StatefulWidget {
  const NativeEditableTextWeb({
    super.key,
    this.textStyle, // TODO: we might want to pass in more specific style - NativeTextStyle - info instead of the whole TextStyle, since some of it (e.g. decoration) can't be applied to the input element.
    // TODO: Can we support this on iOS, Android, etc? It might be fine to keep this here, but not expose it on BasicTextField.
    // TODO: Is a default cursor of black sensible? If no, we might want this to be nullable?
    this.cursorColor = const Color(0xFF000000),
    // TODO: Can we support this on iOS, Android, etc? It might be fine to keep this here, but not expose it on BasicTextField.
    this.showCursor = true,
    // required this.forceLine, // TODO: Remove? TextField doesn't use this.
    this.focusNode,
    required this.maxLines,
    this.minLines,
    this.expands = false,
    this.selectionColor,
    this.textScaler,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.locale,
    // required this.offset,
    // this.rendererIgnoresPointer = false, // TODO: Remove?
    // required this.devicePixelRatio, // TODO: Remove?
    this.clipBehavior = Clip.hardEdge,
    required this.clientId,
    required this.performAction,
    required this.textInputConfiguration, // TODO: we might want to pass in a more specific configuration instead of the whole TextInputConfiguration. This contains a bunch of things like obscureText, readOnly, autofillHints, etc.
    this.currentAutofillScope, // TODO: we might want to pass in a more specific configuration instead of the whole AutofillScope. This contains a bunch of things like obscureText, readOnly, autofillHints, etc.
    // this.scrollTop = 0, // TODO: Remove?
    // this.scrollLeft = 0, // TODO: Remove?
    required this.textEditingValue,
    required this.updateEditingValue,
  });

  final TextStyle? textStyle;
  final Color cursorColor;
  final bool showCursor;
  // final bool forceLine;
  final FocusNode? focusNode;
  final int? maxLines;
  final int? minLines;
  final bool expands;
  final Color? selectionColor;
  final TextScaler? textScaler;
  final TextAlign textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  // final ViewportOffset offset;
  // final bool rendererIgnoresPointer;
  // final double devicePixelRatio;
  final Clip clipBehavior;
  final int clientId;
  final void Function(TextInputAction) performAction;
  final TextInputConfiguration textInputConfiguration;
  final AutofillScope? currentAutofillScope;
  // final double scrollTop;
  // final double scrollLeft;
  final String textEditingValue;
  final void Function(TextEditingValue) updateEditingValue;

  @override
  State<NativeEditableTextWeb> createState() => _NativeEditableTextWebState();
}

class _NativeEditableTextWebState extends State<NativeEditableTextWeb> {
  FocusNode? _focusNode;
  FocusNode get _effectiveFocusNode => widget.focusNode ?? (_focusNode ??= FocusNode());

  @override
  void dispose() {
    _focusNode?.dispose();
    super.dispose();
  }

  void _handleFocused() {
    _effectiveFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final TextDirection textDirection = widget.textDirection ?? Directionality.of(context);

    // TODO: This needs to be the system text scaler to ensure accurate size estimations.
    final TextScaler textScaler = widget.textScaler ?? const TextScaler.linear(1.0);

    return _NativeEditableWeb(
      showCursor: widget.showCursor,
      cursorColor: widget.cursorColor,
      hasFocus: _effectiveFocusNode.hasFocus,
      maxLines: widget.maxLines,
      textScaler: textScaler,
      textDirection: textDirection,
      clipBehavior: widget.clipBehavior,
      onFocused: _handleFocused,
      clientId: widget.clientId,
      performAction: widget.performAction,
      textInputConfiguration: widget.textInputConfiguration,
      textEditingValue: widget.textEditingValue,
      updateEditingValue: widget.updateEditingValue,
    );
  }
}

class _NativeEditableWeb extends StatefulWidget {
  const _NativeEditableWeb({
    super.key,
    this.textStyle,
    required this.cursorColor,
    required this.showCursor,
    // required this.forceLine, // TODO: Remove? TextField doesn't use this.
    required this.hasFocus,
    required this.maxLines,
    this.minLines,
    this.expands = false,
    this.selectionColor,
    required this.textScaler,
    this.textAlign = TextAlign.start,
    required this.textDirection,
    this.locale,
    // required this.offset,
    // this.rendererIgnoresPointer = false, // TODO: Remove?
    // required this.devicePixelRatio, // TODO: Remove?
    required this.clipBehavior,
    required this.onFocused,
    required this.clientId,
    required this.performAction,
    required this.textInputConfiguration, // TODO: we might want to pass in a more specific configuration instead of the whole TextInputConfiguration. This contains a bunch of things like obscureText, readOnly, autofillHints, etc.
    this.currentAutofillScope, // TODO: we might want to pass in a more specific configuration instead of the whole AutofillScope. This contains a bunch of things like obscureText, readOnly, autofillHints, etc.
    // required this.scrollTop, // TODO: Remove?
    // required this.scrollLeft, // TODO: Remove?
    required this.textEditingValue,
    required this.updateEditingValue,
  });

  final TextStyle? textStyle;
  final Color cursorColor;
  final bool showCursor;
  // final bool forceLine;
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
  // final bool rendererIgnoresPointer;
  // final double devicePixelRatio;
  final Clip clipBehavior;
  final VoidCallback onFocused;
  final int clientId;
  final void Function(TextInputAction) performAction;
  final TextInputConfiguration textInputConfiguration;
  final AutofillScope? currentAutofillScope;
  // final double scrollTop;
  // final double scrollLeft;
  final String textEditingValue;
  final void Function(TextEditingValue) updateEditingValue;

  @override
  State<_NativeEditableWeb> createState() => _NativeEditableWebState();
}

class _NativeEditableWebState extends State<_NativeEditableWeb> {
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

  Size estimateSize(BoxConstraints constraints) {
    // TODO: Cache the text painter.
    // TODO: Improve this estimate. Incorrect esimates are noticeable in a growable
    // text field when the text field grows at an unexpected time.
    // TODO: What happens if the user is composing text?
    // The text field might need to grow.
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: widget.textEditingValue, style: widget.textStyle),
      textAlign: widget.textAlign,
      textDirection: widget.textDirection,
      maxLines: widget.maxLines,
      locale: widget.locale,
      textScaler: widget.textScaler,
    );

    textPainter.layout(minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);

    return textPainter.size;
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
      cssProperties.add('font-style: ${style.fontStyle == FontStyle.italic ? 'italic' : 'normal'}');
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
  String textAlignToCssValue(ui.TextAlign? align, ui.TextDirection textDirection) {
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
        return <String, String>{'type': 'number', 'inputmode': isDecimal ? 'decimal' : 'numeric'};
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
        widget.showCursor ? colorToCss(widget.cursorColor) : 'transparent',
      )
      ..outline = 'none'
      ..border = 'none'
      ..background = 'transparent'
      ..padding = '0'
      ..overflow = 'hidden'
      ..textAlign = textAlignToCssValue(widget.textAlign, widget.textDirection)
      ..resize = 'none'
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
      // TODO(loic-sharma): I changed the class from .customInputSelection to .flt-text-field-platform-view.
      // Is there a better class to distinguish the web text field platform view?
      // NOTE: iOS Safari does not support ::selection.
      // https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Selectors/::selection#browser_compatibility
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
      html.document
          .querySelector('flt-glass-pane')!
          .style
          .setProperty('--selection-background', colorToCss(widget.selectionColor!));

      // To ensure we're only modifying selection on this specific input, we attach a custom class
      // instead of adding a blanket rule for all inputs.
      inputEl.classes.add('flt-text-field-platform-view');
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
        extentOffset: element.selectionEnd ?? 0,
      );

      print('handle change value ${text}');
      print('handle change selection ${element.selectionStart} - ${element.selectionEnd}');
      final TextEditingValue newEditingState = TextEditingValue(text: text, selection: selection);

      if (newEditingState != lastEditingState) {
        lastEditingState = newEditingState;
        print('updateEditingState');
        updateEditingState(newEditingState);
      }
    } else if (isInput(_inputEl)) {
      final html.InputElement element = _inputEl as html.InputElement;
      final String text = element.value!;
      final TextSelection selection = TextSelection(
        baseOffset: element.selectionStart ?? 0,
        extentOffset: element.selectionEnd ?? 0,
      );

      print('handle change value ${text}');
      print('handle change selection ${element.selectionStart} - ${element.selectionEnd}');
      final TextEditingValue newEditingState = TextEditingValue(text: text, selection: selection);

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
      widget.onFocused.call();

      // TODO: This was necessary because of TextField's weird behavior.
      // (TextField sets selectionColor to null when it doesn't have focus).
      //
      if (widget.selectionColor != null) {
        // Since we're relying on a CSS variable to handle selection background, we
        // run into an issue when there are multiple inputs with multiple selection background
        // values. In that case, the variable is always set to whatever the last rendered input's selection
        // background value was set to.  To fix this, we update that CSS variable to the currently focused
        // element's selection color value.
        inputEl.classes.add('flt-text-field-platform-view');
        html.document
            .querySelector('flt-glass-pane')!
            .style
            .setProperty('--selection-background', colorToCss(widget.selectionColor!));
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

    inputEl.setAttribute('autocorrect', widget.textInputConfiguration.autocorrect ? 'on' : 'off');

    final String? enterKeyHint = getEnterKeyHint(widget.textInputConfiguration.inputAction);

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
      final Map<String, String> attributes = getKeyboardTypeAttributes(
        widget.textInputConfiguration.inputType,
      );
      inputEl.type = attributes['type'];
      inputEl.inputMode = attributes['inputmode'];
    }

    if (widget.textInputConfiguration.autofillConfiguration.autofillHints.isNotEmpty) {
      // browsers can only use one autocomplete attribute
      final String autocomplete = _getAutocompleteAttribute(
        widget.textInputConfiguration.autofillConfiguration.autofillHints.first,
      );
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
    final Iterable<AutofillClient> autofillClients = widget.currentAutofillScope!.autofillClients;
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

    final String autofillId = widget.textInputConfiguration.autofillConfiguration.uniqueIdentifier;

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
      print('maybeSendAction: performed action ${widget.textInputConfiguration.inputAction}');

      // Prevent the browser from inserting a new line when it's not a multiline input.
      // note: taken from engine. Do we still need?
      // if (widget.textInputConfiguration.inputType != TextInputType.multiline) {
      // event.preventDefault();
      // }
    }
  }

  @override
  void didUpdateWidget(_NativeEditableWeb oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.hasFocus != oldWidget.hasFocus) {
      if (widget.hasFocus) {
        _inputEl.focus();
      } else {
        _inputEl.blur();
      }
    }

    // we do this because widget can sometimes selectionColor can be passed
    // as conditionally null depending on some state that's determined in a layer
    // above (e.g. `hasFocus`), so we need to keep track of the selectionColor
    // and set it when appropriate.
    if (widget.selectionColor != oldWidget.selectionColor) {
      if (widget.selectionColor != null) {
        html.document
            .querySelector('flt-glass-pane')!
            .style
            .setProperty('--selection-background', colorToCss(widget.selectionColor!));
        _inputEl.classes.add('flt-text-field-platform-view');
      }
    }
  }

  // single EditableWeb that is a form owner for both cases.
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size estimatedSize = estimateSize(constraints);
        return SizedBox(
          width: estimatedSize.width,
          height: estimatedSize.height,
          child: ExcludeFocus(
            child: HtmlElementView.fromTagName(
              tagName: _isMultiline ? 'textarea' : 'input',
              onElementCreated: (Object element) {
                initializePlatformView(element as html.HtmlElement);
              },
            ),
          ),
        );
      },
    );
  }
}

bool isInput(html.HtmlElement el) {
  return el.tagName.toUpperCase() == 'INPUT';
}

bool isTextArea(html.HtmlElement el) {
  return el.tagName.toUpperCase() == 'TEXTAREA';
}
