import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;

class AdaptiveRPSClipper extends StatelessWidget {
  final double width;
  final double height;
  final Widget child;
  final bool mirrored;

  const AdaptiveRPSClipper({
    super.key,
    required this.width,
    required this.height,
    required this.child,
    this.mirrored = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ClipPath(
        clipper: _RPSPathClipper(width: width, height: height, mirrored: mirrored),
        child: child,
      ),
    );
  }
}

class _RPSPathClipper extends CustomClipper<Path> {
  final double width;
  final double height;
  final bool mirrored;

  _RPSPathClipper({required this.width, required this.height, this.mirrored = false});

  @override
  Path getClip(Size size) {
    // Original painter size
    const double originalWidth = 56.8067;
    const double originalHeight = 156.797;

    // Scale factors
    final double sx = width / originalWidth;
    final double sy = height / originalHeight;

    Path p = Path();
    p.moveTo(0, 0);
    p.lineTo(0, 17.9006 * sy);
    p.cubicTo(0, 24.9122 * sy, 3.67183 * sx, 31.4119 * sy, 9.67739 * sx, 35.0308 * sy);
    p.lineTo(36.1616 * sx, 50.9901 * sy);
    p.cubicTo(56.8067 * sx, 63.4308 * sy, 56.8067 * sx, 93.3661 * sy, 36.1616 * sx, 105.807 * sy);
    p.lineTo(9.67738 * sx, 121.766 * sy);
    p.cubicTo(3.67183 * sx, 125.385 * sy, 0, 131.885 * sy, 0, 138.896 * sy);
    p.lineTo(0, 156.797 * sy);
    p.close();

    if (mirrored) {
      final Matrix4 m = Matrix4.identity();
      m.translateByVector3(vmath.Vector3(width, 0, 0));
      m.scaleByVector3(vmath.Vector3(-1.0, 1.0, 1.0));
      return p.transform(m.storage);
    }

    return p;
  }

  @override
  bool shouldReclip(covariant _RPSPathClipper oldClipper) {
    return oldClipper.width != width ||
        oldClipper.height != height ||
        oldClipper.mirrored != mirrored;
  }
}
