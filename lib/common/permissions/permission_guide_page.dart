import 'package:flutter/material.dart';
import 'package:oncue_mobile/common/design_system/widgets/app_card.dart';
import 'package:oncue_mobile/common/design_system/widgets/icon_badge.dart';
import 'package:oncue_mobile/common/design_system/widgets/oncue_app_bar.dart';
import 'package:oncue_mobile/common/design_system/widgets/primary_button.dart';
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const OnCueAppBar(title: '통화 권한 안내'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
              child: Column(
                children: [
                  const IconBadge(
                    icon: Icons.verified_user,
                    variant: IconBadgeVariant.accent,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '예약된 전화를 받으려면',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '통화 권한과 시스템 통화 기능이 필요해요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (_errorMessage case final error?) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.error.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber, color: theme.colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            PrimaryButton(
              key: const ValueKey('request-call-permission-button'),
              onPressed: _isRequesting ? null : _requestPermissions,
              label: '권한 확인하기',
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
