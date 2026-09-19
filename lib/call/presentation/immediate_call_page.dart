import 'dart:async';

import 'package:flutter/material.dart';
import 'package:oncue_mobile/call/application/immediate_call_test_service.dart';
import 'package:oncue_mobile/combination/model/call_combination_card.dart';

final class ImmediateCallPage extends StatefulWidget {
  const ImmediateCallPage({
    super.key,
    required this.reservationId,
    required this.accessToken,
    required this.combination,
    required this.callService,
  });

  final String reservationId;
  final String? accessToken;
  final CallCombinationCard combination;
  final ImmediateCallTestService callService;

  @override
  State<ImmediateCallPage> createState() => _ImmediateCallPageState();
}

final class _ImmediateCallPageState extends State<ImmediateCallPage> {
  bool _isConnected = false;
  bool _isClosing = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_startCall());
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    return Scaffold(
      appBar: AppBar(title: const Text('개발용 통화 테스트')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        widget.combination.personaImageAsset,
                        width: 220,
                        height: 220,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const ColoredBox(
                          color: Color(0xFFE8EAF6),
                          child: SizedBox(
                            width: 220,
                            height: 220,
                            child: Icon(Icons.person, size: 72),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.combination.personaName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error == null
                          ? (_isConnected ? '통화 중' : '통화 연결 중...')
                          : '통화 연결에 실패했습니다.',
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 8),
                      const Text('서버 로그에서 WebRTC 연결 상태를 확인해 주세요.'),
                    ],
                    if (!_isConnected && error == null) ...[
                      const SizedBox(height: 16),
                      const CircularProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
            FilledButton.icon(
              key: const ValueKey('end-immediate-call-button'),
              onPressed: _isClosing ? null : _endCall,
              icon: const Icon(Icons.call_end),
              label: Text(error == null ? '통화 종료' : '닫기'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startCall() async {
    try {
      await widget.callService.start(
        widget.reservationId,
        accessToken: widget.accessToken,
      );
      if (!mounted) {
        return;
      }
      setState(() => _isConnected = true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error);
    }
  }

  Future<void> _endCall() async {
    setState(() => _isClosing = true);
    if (_error == null) {
      await widget.callService.hangup();
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
