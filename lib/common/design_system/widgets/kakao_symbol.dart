import 'package:flutter/material.dart';

/// The KakaoTalk speech-bubble mark used on the Kakao login button.
///
/// Rendered from the same path geometry as `icon_talk_login.svg` bundled
/// with the `kakao_flutter_sdk_user` dependency already in this project —
/// drawn with [CustomPainter] instead of an SVG asset so no SVG-rendering
/// package needs to be added.
final class KakaoSymbol extends StatelessWidget {
  const KakaoSymbol({super.key, this.size = 18, this.color = const Color(0xFF191600)});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _KakaoSymbolPainter(color)),
    );
  }
}

final class _KakaoSymbolPainter extends CustomPainter {
  const _KakaoSymbolPainter(this.color);

  static const double _viewBoxWidth = 19;
  static const double _viewBoxHeight = 20;

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _viewBoxWidth, size.height / _viewBoxHeight);

    final path = Path()
      ..moveTo(9.5005, 3.08081)
      ..cubicTo(13.2685, 3.08091, 16.3418, 5.72991, 16.3419, 9.03952)
      ..cubicTo(16.3419, 12.3424, 13.2685, 14.9915, 9.5005, 14.9916)
      ..cubicTo(9.1365, 14.9916, 8.77883, 14.9712, 8.42831, 14.924)
      ..lineTo(8.37397, 14.9134)
      ..lineTo(6.5079, 16.3004)
      ..cubicTo(5.91032, 16.7443, 5.06157, 16.3205, 5.05732, 15.5761)
      ..lineTo(5.04605, 13.5602)
      ..lineTo(5.03147, 13.549)
      ..cubicTo(3.36652, 12.3491, 2.68543, 11.2233, 2.65846, 9.16741)
      ..lineTo(2.65846, 9.03289)
      ..cubicTo(2.65846, 5.72993, 5.73244, 3.08081, 9.5005, 3.08081)
      ..close();

    canvas.drawPath(path, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _KakaoSymbolPainter oldDelegate) =>
      oldDelegate.color != color;
}
