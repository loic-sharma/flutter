// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cmake.dart';
import 'package:flutter_tools/src/project.dart';

import '../src/common.dart';
import '../src/context.dart';

const String _kTestFlutterRoot = '/flutter';
const String _kTestWindowsFlutterRoot = r'C:\flutter';

void main() {
  FileSystem fileSystem;

  ProcessManager processManager;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
  });

  testUsingContext('parses executable name from cmake file', () async {
    final FlutterProject project = FlutterProject.fromDirectoryTest(fileSystem.currentDirectory);
    final CmakeBasedProject cmakeProject = _FakeProject.fromFlutter(project);

    cmakeProject.cmakeFile
      ..createSync(recursive: true)
      ..writeAsStringSync('set(BINARY_NAME "hello")');

    final String name = getCmakeExecutableName(cmakeProject);

    expect(name, 'hello');
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('defaults executable name to null if cmake config does not exist', () async {
    final FlutterProject project = FlutterProject.fromDirectoryTest(fileSystem.currentDirectory);
    final CmakeBasedProject cmakeProject = _FakeProject.fromFlutter(project);

    final String name = getCmakeExecutableName(cmakeProject);

    expect(name, isNull);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('generates config', () async {
    final FlutterProject project = FlutterProject.fromDirectoryTest(fileSystem.currentDirectory);
    final CmakeBasedProject cmakeProject = _FakeProject.fromFlutter(project);
    final Map<String, String> environment = <String, String>{};

    writeGeneratedCmakeConfig(
      _kTestFlutterRoot,
      cmakeProject,
      environment,
    );

    final File cmakeConfig = cmakeProject.generatedCmakeConfigFile;

    expect(cmakeConfig, exists);

    final List<String> configLines = cmakeConfig.readAsLinesSync();

    expect(configLines, containsAll(<String>[
      r'# Generated code do not commit.',
      r'file(TO_CMAKE_PATH "/flutter" FLUTTER_ROOT)',
      r'file(TO_CMAKE_PATH "/" PROJECT_DIR)',

      r'# Environment variables to pass to tool_backend.sh',
      r'list(APPEND FLUTTER_TOOL_ENVIRONMENT',
      r'  "FLUTTER_ROOT=/flutter"',
      r'  "PROJECT_DIR=/"',
      r')',
    ]));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });

  testUsingContext('config escapes backslashes', () async {
    fileSystem = MemoryFileSystem.test(style: FileSystemStyle.windows);

    final FlutterProject project = FlutterProject.fromDirectoryTest(fileSystem.currentDirectory);
    final CmakeBasedProject cmakeProject = _FakeProject.fromFlutter(project);

    final Map<String, String> environment = <String, String>{
      'TEST': r'hello\world',
    };

    writeGeneratedCmakeConfig(
      _kTestWindowsFlutterRoot,
      cmakeProject,
      environment,
    );

    final File cmakeConfig = cmakeProject.generatedCmakeConfigFile;

    expect(cmakeConfig, exists);

    final List<String> configLines = cmakeConfig.readAsLinesSync();

    expect(configLines, containsAll(<String>[
      r'# Generated code do not commit.',
      r'file(TO_CMAKE_PATH "C:\\flutter" FLUTTER_ROOT)',
      r'file(TO_CMAKE_PATH "C:\\" PROJECT_DIR)',

      r'# Environment variables to pass to tool_backend.sh',
      r'list(APPEND FLUTTER_TOOL_ENVIRONMENT',
      r'  "FLUTTER_ROOT=C:\\flutter"',
      r'  "PROJECT_DIR=C:\\"',
      r'  "TEST=hello\\world"',
      r')',
    ]));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  });
}

class _FakeProject implements CmakeBasedProject {
  _FakeProject.fromFlutter(this._parent);

  final FlutterProject _parent;

  @override
  bool existsSync() => _editableDirectory.existsSync();

  @override
  File get cmakeFile => _editableDirectory.childFile('CMakeLists.txt');

  @override
  File get managedCmakeFile => _managedDirectory.childFile('CMakeLists.txt');

  @override
  File get generatedCmakeConfigFile => _ephemeralDirectory.childFile('generated_config.cmake');

  @override
  File get generatedPluginCmakeFile => _managedDirectory.childFile('generated_plugins.cmake');

  @override
  Directory get pluginSymlinkDirectory => _ephemeralDirectory.childDirectory('.plugin_symlinks');

  @override
  FlutterProject get parent => _parent;

  Directory get _editableDirectory => parent.directory.childDirectory('test');
  Directory get _managedDirectory => _editableDirectory.childDirectory('flutter');
  Directory get _ephemeralDirectory => _managedDirectory.childDirectory('ephemeral');
}
