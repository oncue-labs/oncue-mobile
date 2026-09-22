import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/common/call/method_channel_system_call_manager.dart';
import 'package:oncue_mobile/common/call/system_call_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(MethodChannelSystemCallManager.channelName);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('sends call commands through the native channel', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
    final manager = MethodChannelSystemCallManager();
    addTearDown(manager.dispose);

    await manager.presentIncomingCall(
      const IncomingCallDisplayInfo(
        callSessionId: '12345',
        displayName: '산타',
        callType: 'voice',
      ),
    );
    await manager.endCall('12345');
    await manager.answerSucceeded('12345');
    await manager.answerFailed('12345');

    expect(calls.map((call) => call.method), [
      'presentIncomingCall',
      'endCall',
      'answerSucceeded',
      'answerFailed',
    ]);
    expect(calls[0].arguments, {
      'callSessionId': '12345',
      'displayName': '산타',
      'callType': 'voice',
    });
    expect(calls[1].arguments, {'callSessionId': '12345'});
    expect(calls[2].arguments, {'callSessionId': '12345'});
    expect(calls[3].arguments, {'callSessionId': '12345'});
  });

  test('notifies native code after Dart call handlers are ready', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
    final manager = MethodChannelSystemCallManager();
    addTearDown(manager.dispose);

    await manager.markReady();

    expect(calls, hasLength(1));
    expect(calls.single.method, 'systemCallChannelReady');
    expect(calls.single.arguments, isNull);
  });

  test('publishes native lifecycle events with the call session id', () async {
    final manager = MethodChannelSystemCallManager();
    addTearDown(manager.dispose);

    final answered = expectLater(manager.onAnswered, emits('12345'));
    final rejected = expectLater(manager.onRejected, emits('12345'));
    final ended = expectLater(manager.onEnded, emits('12345'));
    final audioActivated = expectLater(
      manager.onAudioActivated,
      emits('12345'),
    );

    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const codec = StandardMethodCodec();
    await messenger.handlePlatformMessage(
      channel.name,
      codec.encodeMethodCall(const MethodCall('onAnswered', '12345')),
      (_) {},
    );
    await messenger.handlePlatformMessage(
      channel.name,
      codec.encodeMethodCall(const MethodCall('onRejected', '12345')),
      (_) {},
    );
    await messenger.handlePlatformMessage(
      channel.name,
      codec.encodeMethodCall(const MethodCall('onEnded', '12345')),
      (_) {},
    );
    await messenger.handlePlatformMessage(
      channel.name,
      codec.encodeMethodCall(const MethodCall('onAudioActivated', '12345')),
      (_) {},
    );

    await Future.wait([answered, rejected, ended, audioActivated]);
  });

  test('rejects malformed native lifecycle events', () async {
    final manager = MethodChannelSystemCallManager();
    addTearDown(manager.dispose);

    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const codec = StandardMethodCodec();

    final response = await messenger.handlePlatformMessage(
      channel.name,
      codec.encodeMethodCall(const MethodCall('onAnswered', 12345)),
      (_) {},
    );

    expect(response, isNotNull);
    expect(
      () => codec.decodeEnvelope(response!),
      throwsA(isA<PlatformException>()),
    );
  });
}
