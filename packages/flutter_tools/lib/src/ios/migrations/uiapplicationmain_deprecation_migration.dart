// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../base/file_system.dart';
import '../../base/project_migrator.dart';
import '../../xcode_project.dart';

const String _appDelegateFileBefore = r'''
@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
''';

const String _appDelegateFileAfter = r'''
@main
@objc class AppDelegate: FlutterAppDelegate {
''';

/// Replace the deprecated `@UIApplicationMain` attribute with `@main`.
///
/// See:
/// https://github.com/apple/swift-evolution/blob/main/proposals/0383-deprecate-uiapplicationmain-and-nsapplicationmain.md
class UIApplicationmMainDeprecationMigration extends ProjectMigrator {
  UIApplicationmMainDeprecationMigration(
    IosProject project,
    super.logger,
  )   : _appDelegateSwift = project.appDelegateSwift;

  final File _appDelegateSwift;

  @override
  Future<bool> migrate() async {
    // Skip this migration if the project uses Objective-C.
    if (!_appDelegateSwift.existsSync()) {
      return true;
    }

    // Migrate the ios/Runner/AppDelegate.swift file.
    final String original = _appDelegateSwift.readAsStringSync();
    final String migrated = original.replaceFirst(_appDelegateFileBefore, _appDelegateFileAfter);
    if (original == migrated) {
      return true;
    }

    logger.printStatus(
      'ios/Runner/AppDelegate.swift does not use the @main attribute, updating.',
    );
    _appDelegateSwift.writeAsStringSync(migrated);
    return true;
  }
}
