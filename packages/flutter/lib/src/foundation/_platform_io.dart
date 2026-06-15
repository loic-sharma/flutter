// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'assertions.dart';
import 'constants.dart';
import 'platform.dart' as platform;

export 'platform.dart' show TargetPlatform;

/// The dart:io implementation of [platform.defaultTargetPlatform].
@pragma('vm:platform-const-if', !kDebugMode)
platform.TargetPlatform get defaultTargetPlatform {
  platform.TargetPlatform? result;
  if (Platform.isAndroid) {
    result = platform.TargetPlatform.android;
  } else if (Platform.isIOS) {
    result = platform.TargetPlatform.iOS;
  } else if (Platform.isFuchsia) {
    result = platform.TargetPlatform.fuchsia;
  } else if (Platform.isLinux) {
    result = platform.TargetPlatform.linux;
  } else if (Platform.isMacOS) {
    result = platform.TargetPlatform.macOS;
  } else if (Platform.isWindows) {
    result = platform.TargetPlatform.windows;
  }
  assert(() {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      result = platform.TargetPlatform.android;
    }
    return true;
  }());
  if (kDebugMode && platform.debugDefaultTargetPlatformOverride != null) {
    result = platform.debugDefaultTargetPlatformOverride;
  }
  if (result == null) {
    throw FlutterError(
      'Unknown platform.\n'
      '${Platform.operatingSystem} was not recognized as a target platform. '
      'Consider updating the list of TargetPlatforms to include this platform.',
    );
  }
  return result!;
}

/// The dart:io implementation of [platform.defaultIsDesktop].
@pragma('vm:platform-const-if', !kDebugMode)
bool get defaultIsDesktop {
  if (kDebugMode && platform.debugDefaultIsDesktopOverride != null) {
    return platform.debugDefaultIsDesktopOverride!;
  }
  if (kDebugMode && platform.debugDefaultTargetPlatformOverride != null) {
    final platform.TargetPlatform tp = platform.debugDefaultTargetPlatformOverride!;
    return tp == platform.TargetPlatform.linux ||
        tp == platform.TargetPlatform.macOS ||
        tp == platform.TargetPlatform.windows;
  }
  bool result = const bool.hasEnvironment('flutter.is_desktop')
      ? const bool.fromEnvironment('flutter.is_desktop')
      : (Platform.isLinux || Platform.isMacOS || Platform.isWindows);
  assert(() {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      result = false;
    }
    return true;
  }());
  return result;
}

/// The dart:io implementation of [platform.defaultIsMobile].
@pragma('vm:platform-const-if', !kDebugMode)
bool get defaultIsMobile {
  if (kDebugMode && platform.debugDefaultIsMobileOverride != null) {
    return platform.debugDefaultIsMobileOverride!;
  }
  if (kDebugMode && platform.debugDefaultTargetPlatformOverride != null) {
    final platform.TargetPlatform tp = platform.debugDefaultTargetPlatformOverride!;
    return tp == platform.TargetPlatform.android ||
        tp == platform.TargetPlatform.iOS ||
        tp == platform.TargetPlatform.fuchsia;
  }
  bool result = const bool.hasEnvironment('flutter.is_mobile')
      ? const bool.fromEnvironment('flutter.is_mobile')
      : (Platform.isAndroid || Platform.isIOS || Platform.isFuchsia);
  assert(() {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      result = true;
    }
    return true;
  }());
  return result;
}

/// The dart:io implementation of [platform.defaultIsDarwin].
@pragma('vm:platform-const-if', !kDebugMode)
bool get defaultIsDarwin {
  if (kDebugMode && platform.debugDefaultIsDarwinOverride != null) {
    return platform.debugDefaultIsDarwinOverride!;
  }
  if (kDebugMode && platform.debugDefaultTargetPlatformOverride != null) {
    final platform.TargetPlatform tp = platform.debugDefaultTargetPlatformOverride!;
    return tp == platform.TargetPlatform.iOS || tp == platform.TargetPlatform.macOS;
  }
  bool result = const bool.hasEnvironment('flutter.is_darwin')
      ? const bool.fromEnvironment('flutter.is_darwin')
      : (Platform.isIOS || Platform.isMacOS);
  assert(() {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      result = false;
    }
    return true;
  }());
  return result;
}
