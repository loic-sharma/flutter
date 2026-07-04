// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/semantics.dart';
/// @docImport 'package:flutter/widgets.dart';
library;

import 'package:meta/meta.dart';

import 'diagnostics.dart';

/// A [Key] is an identifier for [Widget]s, [Element]s and [SemanticsNode]s.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=kn0EOS-ZiIc}
///
/// {@template flutter.foundation.Key}
/// Keys let you move [StatefulWidget]s around in the widget tree without
/// losing their state. For example, you can use keys to preserve state when
/// you change a collection of stateful widgets (e.g., add, remove, or reorder
/// widgets in a [Row]). Or, you can use [GlobalKey]s to preserve state when
/// you move a widget in the tree from one parent to another parent.
///
/// A new widget will only be used to update an existing element if its
/// [Widget.runtimeType] and [Widget.key] are the same as the element's
/// current widget. Otherwise, the old element is removed from the tree, the
/// new widget is inflated into an element, and the new element is inserted
/// into the tree.
/// {@endtemplate}
///
/// Keys must be unique amongst the [Element]s with the same parent.
/// [GlobalKey]s must be unique across the entire app.
///
/// Subclasses of [Key] should either subclass [LocalKey] or [GlobalKey].
///
/// {@tool dartpad}
/// This sample shows two randomly colored boxes. When the user taps the button,
/// the two boxes swap places. The state (color) swaps only if the boxes have
/// keys.
///
/// ** See code in examples/api/lib/widgets/key/key.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [Widget.key], which discusses how widgets use keys.
@immutable
@pragma('flutter:keep-to-string-in-subtypes')
abstract class Key {
  /// Construct a [ValueKey<String>] with the given [String].
  ///
  /// This is the simplest way to create keys.
  const factory Key(String value) = ValueKey<String>;

  /// Default constructor, used by subclasses.
  ///
  /// Useful so that subclasses can call us, because the [Key.new] factory
  /// constructor shadows the implicit constructor.
  @protected
  const Key.empty();
}

/// A key that is not a [GlobalKey].
///
/// Keys must be unique amongst the [Element]s with the same parent. By
/// contrast, [GlobalKey]s must be unique across the entire app.
///
/// See also:
///
///  * [Widget.key], which discusses how widgets use keys.
abstract class LocalKey extends Key {
  /// This constructor enables subclasses to provide const constructors so that
  /// they can be used in const expressions.
  const LocalKey() : super.empty();
}

/// A key that is only equal to itself.
///
/// This cannot be created with a const constructor because that implies that
/// all instantiated keys would be the same instance and therefore not be unique.
class UniqueKey extends LocalKey {
  /// Creates a key that is equal only to itself.
  ///
  /// The key cannot be created with a const constructor because that implies
  /// that all instantiated keys would be the same instance and therefore not
  /// be unique.
  // ignore: prefer_const_constructors_in_immutables , never use const for this class
  UniqueKey();

  @override
  String toString() => '[#${shortHash(this)}]';
}

/// A key that uses a value of a particular type to identify itself.
///
/// A [ValueKey] is equal to another [ValueKey] if, and only if, their values
/// are equal (using [operator==]).
///
/// This class can be subclassed to create value keys that will not be equal to
/// other value keys that happen to use the same value. If the subclass is
/// private, this results in a value key type that cannot collide with keys from
/// other sources. This is useful when keys are used as fallbacks in the same
/// scope as keys supplied from another widget.
///
/// {@tool dartpad}
/// This sample shows two randomly colored boxes. When the user taps the button,
/// the two boxes swap places. The state (color) swaps only if the boxes have
/// keys.
///
/// ** See code in examples/api/lib/widgets/key/key.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [Widget.key], which discusses how widgets use keys.
///  * [ObjectKey], which uses the identity of an object as the key.
///  * [UniqueKey], which is a key that is only equal to itself.
class ValueKey<T> extends LocalKey {
  /// Creates a key that delegates its [operator==] to the given value.
  const ValueKey(this.value);

  /// The value to which this key delegates its [operator==].
  final T value;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is ValueKey<T> && other.value == value;
  }

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @override
  String toString() {
    final valueString = T == String ? "<'$value'>" : '<$value>';
    if (runtimeType == _TypeOf<ValueKey<T>>) {
      return '[$valueString]';
    }
    return '[$T $valueString]';
  }
}

typedef _TypeOf<T> = T;
