import 'package:flutter/services.dart';
import 'package:oncue_mobile/common/permissions/call_permission_service.dart';

final class MethodChannelCallPermissionService
    implements CallPermissionService {
  const MethodChannelCallPermissionService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'oncue/call_permissions';

  static const _checkRequiredPermissionsMethod = 'checkRequiredPermissions';
  static const _requestMissingPermissionsMethod = 'requestMissingPermissions';
  static const _openSettingsMethod = 'openSettings';

  final MethodChannel _channel;

  @override
  Future<CallPermissionStatus> checkRequiredPermissions() {
    return _invokeStatus(_checkRequiredPermissionsMethod);
  }

  @override
  Future<CallPermissionStatus> requestMissingPermissions() {
    return _invokeStatus(_requestMissingPermissionsMethod);
  }

  @override
  Future<void> openSettings() {
    return _channel.invokeMethod<void>(_openSettingsMethod);
  }

  Future<CallPermissionStatus> _invokeStatus(String method) async {
    final value = await _channel.invokeMethod<String>(method);
    return switch (value) {
      'ready' => CallPermissionStatus.ready,
      'permissionRequired' => CallPermissionStatus.permissionRequired,
      _ => throw StateError('Unknown call permission status: $value'),
    };
  }
}
