import 'package:flutter/material.dart';
import 'package:oncue_mobile/common/permissions/call_permission_service.dart';

final class PermissionGuidePage extends StatefulWidget {
  const PermissionGuidePage({
    super.key,
    required this.requestMissingPermissions,
    required this.openSettings,
  });

  final Future<CallPermissionStatus> Function() requestMissingPermissions;
  final Future<void> Function() openSettings;

  @override
  State<PermissionGuidePage> createState() => _PermissionGuidePageState();
}

final class _PermissionGuidePageState extends State<PermissionGuidePage> {
  bool _isRequesting = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('통화 권한 안내')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('예약된 전화를 받으려면 통화 권한과 시스템 통화 기능이 필요합니다.'),
            const SizedBox(height: 16),
            if (_errorMessage case final error?) ...[
              Text(error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: 16),
            ],
            FilledButton(
              key: const ValueKey('request-call-permission-button'),
              onPressed: _isRequesting ? null : _requestPermissions,
              child: const Text('권한 확인하기'),
            ),
            TextButton(
              key: const ValueKey('open-settings-button'),
              onPressed: _isRequesting ? null : widget.openSettings,
              child: const Text('설정에서 직접 확인하기'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _isRequesting = true;
      _errorMessage = null;
    });
    final status = await widget.requestMissingPermissions();
    if (!mounted) {
      return;
    }
    if (status == CallPermissionStatus.ready) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _isRequesting = false;
      _errorMessage = '필수 권한이 준비되지 않았습니다.';
    });
  }
}
