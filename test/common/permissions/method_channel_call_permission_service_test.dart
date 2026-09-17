import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oncue_mobile/common/permissions/call_permission_service.dart';
import 'package:oncue_mobile/common/permissions/method_channel_call_permission_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(MethodChannelCallPermissionService.channelName);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('maps the native ready result', () async {
    _mock(channel, 'checkRequiredPermissions', 'ready');

    final service = MethodChannelCallPermissionService(channel: channel);

    expect(
      await service.checkRequiredPermissions(),
      CallPermissionStatus.ready,
    );
  });

  test('requests missing permissions through the native channel', () async {
    _mock(channel, 'requestMissingPermissions', 'ready');

    final service = MethodChannelCallPermissionService(channel: channel);

    expect(
      await service.requestMissingPermissions(),
      CallPermissionStatus.ready,
    );
  });

  test('opens the application settings through the native channel', () async {
    var invokedMethod = '';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          invokedMethod = call.method;
          return null;
        });

    final service = MethodChannelCallPermissionService(channel: channel);

    await service.openSettings();

    expect(invokedMethod, 'openSettings');
  });
}

void _mock(MethodChannel channel, String expectedMethod, String result) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
        expect(call.method, expectedMethod);
        return result;
      });
}
