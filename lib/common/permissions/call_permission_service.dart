enum CallPermissionStatus {
  ready,
  permissionRequired,
}

abstract interface class CallPermissionService {
  Future<CallPermissionStatus> checkRequiredPermissions();

  Future<CallPermissionStatus> requestMissingPermissions();

  Future<void> openSettings();
}
