import 'dart:async';

import 'package:flutter/material.dart';
import 'package:oncue_mobile/call/application/immediate_call_test_service.dart';
import 'package:oncue_mobile/combination/model/call_combination_card.dart';
import 'package:oncue_mobile/common/design_system/oncue_typography.dart';

/// Local WebRTC test call screen.
///
/// Not part of `design/mockups` — the mockups only define the in-call
/// look for calls answered through the iOS system (CallKit) screen. This
/// reuses that same full-bleed persona-photo look from
/// `incoming-call.html`'s "통화 연결 후" state since the visual shape
/// (photo background + scrim + name + end control) is identical here.
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            widget.combination.personaImageAsset,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const ColoredBox(color: Color(0xFF2B2F3D)),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xBF05060A),
                  Color(0x1A05060A),
                  Color(0x4005060A),
                  Color(0xD9050A0A),
                ],
                stops: [0, 0.32, 0.6, 1],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Text(
                    widget.combination.personaName,
                    style: pageTitleStyle(context),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    error == null
                        ? (_isConnected ? '통화 중' : '통화 연결 중...')
                        : '통화 연결에 실패했습니다.',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    const Text(
                      '서버 로그에서 WebRTC 연결 상태를 확인해 주세요.',
                      style: TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (!_isConnected && error == null) ...[
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(color: Colors.white),
                  ],
                  const Spacer(),
                  Column(
                    children: [
                      InkWell(
                        key: const ValueKey('end-immediate-call-button'),
                        onTap: _isClosing ? null : _endCall,
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          width: 60,
                          height: 60,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF3B30),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.call_end, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error == null ? '통화 종료' : '닫기',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
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
