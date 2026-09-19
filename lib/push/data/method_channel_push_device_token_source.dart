import 'dart:async';

import 'package:flutter/services.dart';
import 'package:oncue_mobile/push/data/push_device_token_source.dart';

final class MethodChannelPushDeviceTokenSource
    implements PushDeviceTokenSource {
  MethodChannelPushDeviceTokenSource({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName) {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  static const channelName = 'oncue/push_devices';

  final MethodChannel _channel;
  final StreamController<String> _tokenController =
      StreamController<String>.broadcast();

  @override
  Future<String?> currentDeviceToken() async {
    final token = await _channel.invokeMethod<Object?>('currentVoipPushToken');
    if (token is! String) {
      return null;
    }
    final normalizedToken = token.trim();
    return normalizedToken.isEmpty ? null : normalizedToken;
  }

  @override
  Stream<String> get tokenUpdates => _tokenController.stream;

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method != 'onPushTokenUpdated' || call.arguments is! String) {
      return;
    }
    final token = (call.arguments as String).trim();
    if (token.isNotEmpty) {
      _tokenController.add(token);
    }
  }

  Future<void> dispose() => _tokenController.close();
}
