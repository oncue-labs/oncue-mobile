import 'package:oncue_mobile/combination/model/call_combination_card.dart';
import 'package:oncue_mobile/common/permissions/call_permission_service.dart';
import 'package:oncue_mobile/reservation/data/reservation_api_client.dart';
import 'package:oncue_mobile/reservation/model/reservation.dart';

final class CallPermissionRequiredException implements Exception {
  const CallPermissionRequiredException(this.status);

  final CallPermissionStatus status;
}

final class ReservationService {
  ReservationService(this._reservationClient, this._permissionService);

  final ReservationClient _reservationClient;
  final CallPermissionService _permissionService;

  Future<Reservation> createFromCard({
    required CallCombinationCard combination,
    required String scenarioContext,
    required String callGoal,
    required DateTime scheduledAtLocal,
    required String timeZone,
    String? accessToken,
  }) async {
    await _ensurePermissionsReady();
    return _reservationClient.create(
      _input(
        combination: combination,
        scenarioContext: scenarioContext,
        callGoal: callGoal,
        scheduledAtLocal: scheduledAtLocal,
        timeZone: timeZone,
      ),
      accessToken: accessToken,
    );
  }

  Future<Reservation> edit({
    required String reservationId,
    required CallCombinationCard combination,
    required String scenarioContext,
    required String callGoal,
    required DateTime scheduledAtLocal,
    required String timeZone,
    String? accessToken,
  }) async {
    await _ensurePermissionsReady();
    return _reservationClient.update(
      reservationId,
      _input(
        combination: combination,
        scenarioContext: scenarioContext,
        callGoal: callGoal,
        scheduledAtLocal: scheduledAtLocal,
        timeZone: timeZone,
      ),
      accessToken: accessToken,
    );
  }

  Future<Reservation> cancel(
    String reservationId, {
    String? accessToken,
  }) {
    return _reservationClient.cancel(
      reservationId,
      accessToken: accessToken,
    );
  }

  Future<CallPermissionStatus> requestMissingPermissions() {
    return _permissionService.requestMissingPermissions();
  }

  Future<void> openPermissionSettings() {
    return _permissionService.openSettings();
  }

  Future<void> _ensurePermissionsReady() async {
    final status = await _permissionService.checkRequiredPermissions();
    if (status != CallPermissionStatus.ready) {
      throw CallPermissionRequiredException(status);
    }
  }

  ReservationInput _input({
    required CallCombinationCard combination,
    required String scenarioContext,
    required String callGoal,
    required DateTime scheduledAtLocal,
    required String timeZone,
  }) {
    return ReservationInput(
      personaKey: combination.personaKey,
      scenarioKey: combination.scenarioKey,
      scenarioContext: scenarioContext,
      callGoal: callGoal,
      scheduledAtLocal: scheduledAtLocal,
      timeZone: timeZone,
    );
  }
}
