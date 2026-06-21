// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// A [BinaryMessenger] used to exercise the synchronous platform-channel
/// wrappers without a real engine. [sendSync] is routed to [onSendSync], and
/// [setMessageHandlerSync] captures the registered handler in [syncHandler].
///
/// These are pure unit tests of the framework wrappers (encode/decode), so no
/// widget binding is initialized; the real synchronous transport is covered by
/// the engine's embedder tests.
class _FakeSyncBinaryMessenger extends BinaryMessenger {
  ByteData? Function(String channel, ByteData? message)? onSendSync;
  SyncMessageHandler? syncHandler;

  @override
  ByteData? sendSync(String channel, ByteData? message) => onSendSync!(channel, message);

  @override
  void setMessageHandlerSync(String channel, SyncMessageHandler? handler) {
    syncHandler = handler;
  }

  // Asynchronous members are unused by these tests.
  @override
  Future<void> handlePlatformMessage(
    String channel,
    ByteData? data,
    PlatformMessageResponseCallback? callback,
  ) async {}

  @override
  Future<ByteData?>? send(String channel, ByteData? message) => null;

  @override
  void setMessageHandler(String channel, MessageHandler? handler) {}
}

void main() {
  const MethodCodec jsonMethod = JSONMethodCodec();
  const MessageCodec<String?> string = StringCodec();

  test('MethodChannel.invokeMethodSync encodes the call and decodes the result', () {
    final messenger = _FakeSyncBinaryMessenger();
    String? sentChannel;
    MethodCall? sentCall;
    messenger.onSendSync = (String channel, ByteData? message) {
      sentChannel = channel;
      sentCall = jsonMethod.decodeMethodCall(message);
      return jsonMethod.encodeSuccessEnvelope('${sentCall!.arguments} world');
    };
    final channel = MethodChannel('sync_ch', jsonMethod, messenger);

    final String? result = channel.invokeMethodSync<String>('sayHello', 'hello');

    expect(sentChannel, 'sync_ch');
    expect(sentCall!.method, 'sayHello');
    expect(sentCall!.arguments, 'hello');
    expect(result, 'hello world');
  });

  test('MethodChannel.invokeMethodSync throws MissingPluginException on null reply', () {
    final messenger = _FakeSyncBinaryMessenger()..onSendSync = (_, _) => null;
    final channel = MethodChannel('sync_ch', jsonMethod, messenger);

    expect(() => channel.invokeMethodSync<void>('x'), throwsA(isA<MissingPluginException>()));
  });

  test('OptionalMethodChannel.invokeMethodSync returns null on null reply', () {
    final messenger = _FakeSyncBinaryMessenger()..onSendSync = (_, _) => null;
    final channel = OptionalMethodChannel('sync_ch', jsonMethod, messenger);

    expect(channel.invokeMethodSync<Object?>('x'), isNull);
  });

  test('MethodChannel.invokeMethodSync surfaces a PlatformException', () {
    final messenger = _FakeSyncBinaryMessenger()
      ..onSendSync = (_, _) =>
          jsonMethod.encodeErrorEnvelope(code: 'E', message: 'boom', details: 'd');
    final channel = MethodChannel('sync_ch', jsonMethod, messenger);

    expect(
      () => channel.invokeMethodSync<void>('x'),
      throwsA(
        isA<PlatformException>()
            .having((PlatformException e) => e.code, 'code', 'E')
            .having((PlatformException e) => e.message, 'message', 'boom'),
      ),
    );
  });

  test('MethodChannel.setMethodCallHandlerSync encodes the handler result', () {
    final messenger = _FakeSyncBinaryMessenger();
    final channel = MethodChannel('sync_ch', jsonMethod, messenger);

    MethodCall? receivedCall;
    channel.setMethodCallHandlerSync((MethodCall call) {
      receivedCall = call;
      return '${call.arguments} world';
    });

    final ByteData? reply = messenger.syncHandler!(
      jsonMethod.encodeMethodCall(const MethodCall('m', 'hello')),
    );

    expect(receivedCall!.method, 'm');
    expect(jsonMethod.decodeEnvelope(reply!), 'hello world');
  });

  test('MethodChannel.setMethodCallHandlerSync(null) clears the handler', () {
    final messenger = _FakeSyncBinaryMessenger();
    final channel = MethodChannel('sync_ch', jsonMethod, messenger);
    channel.setMethodCallHandlerSync((MethodCall call) => null);
    expect(messenger.syncHandler, isNotNull);
    channel.setMethodCallHandlerSync(null);
    expect(messenger.syncHandler, isNull);
  });

  test('BasicMessageChannel.sendSync round trips through the messenger', () {
    final messenger = _FakeSyncBinaryMessenger()
      ..onSendSync = (_, ByteData? message) =>
          string.encodeMessage('${string.decodeMessage(message)!} world');
    final channel = BasicMessageChannel<String?>('sync_ch', string, binaryMessenger: messenger);

    expect(channel.sendSync('hello'), 'hello world');
  });

  test('BasicMessageChannel.setMessageHandlerSync encodes the reply', () {
    final messenger = _FakeSyncBinaryMessenger();
    final channel = BasicMessageChannel<String?>('sync_ch', string, binaryMessenger: messenger);

    channel.setMessageHandlerSync((String? message) => '$message world');
    final ByteData? reply = messenger.syncHandler!(string.encodeMessage('hello'));

    expect(string.decodeMessage(reply), 'hello world');
  });
}
