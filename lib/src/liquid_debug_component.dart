import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_liquid/flame_liquid.dart';
import 'package:flutter/material.dart';

class LiquidDebugDraw extends Component {
  final Space space;
  LiquidDebugDraw(this.space);
  final _random = Random();

  late final Color _outlineColor =
      Color((_random.nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
  late final Color _constraintColor =
      Color((_random.nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
  late final Color _collisionColor =
      Color((_random.nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
  late final Color _shapeColor =
      Color((_random.nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.save();
    drawDebugPaint(canvas);
    canvas.restore();
  }

  void drawDebugPaint(Canvas canvas) {
    space.debugDraw(
        debugDrawCirlceFunc: (pos, angle, radius, outlineColor, fillColor) =>
            _debugDrawCirlceFunc(
                canvas, pos, angle, radius, outlineColor, fillColor),
        debugDrawSegmentFunc: (a, b, color) =>
            _debugDrawSegmentFunc(canvas, a, b, color),
        debugDrawFatSegmentFunc: (a, b, radius, outlineColor, fillColor) =>
            _debugDrawFatSegmentFunc(
                canvas, a, b, radius, outlineColor, fillColor),
        debugDrawPolygonFunc: (verts, radius, outlineColor, fillColor) =>
            _debugDrawPolygonFunc(
                canvas, verts, radius, outlineColor, fillColor),
        debugDrawDotFunc: (sized, pos, color) =>
            _debugDrawDotFunc(canvas, sized, pos, color),
        debugDrawFlag: DebugDrawFlag.drawShape.value |
            DebugDrawFlag.drawConstratint.value |
            DebugDrawFlag.drawCollisionPoint.value,
        colorForShape: _colorForShape,
        shapeOutlineColor: _outlineColor,
        constraintColor: _constraintColor,
        collisionPointColor: _collisionColor);
  }

  void _debugDrawCirlceFunc(Canvas canvas, Vector2 pos, double angle,
      double radius, Color outlineColor, Color fillColor) {
    canvas.save();
    _rotate(canvas: canvas, cx: pos.x, cy: pos.y, angle: angle);
    canvas.drawCircle(
        Offset(pos.x, pos.y),
        radius,
        Paint()
          ..color = outlineColor
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke);
    canvas.drawCircle(
        Offset(pos.x, pos.y),
        radius,
        Paint()
          ..color = fillColor
          ..style = PaintingStyle.fill);
    canvas.drawLine(
        Offset(pos.x, pos.y),
        Offset(pos.x + radius - 1, pos.y),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 1);

    canvas.restore();
  }

  void _rotate(
      {required Canvas canvas,
      required double cx,
      required double cy,
      required double angle}) {
    canvas.translate(cx, cy);
    canvas.rotate(angle);
    canvas.translate(-cx, -cy);
  }

  Color _colorForShape(Shape shape) {
    if (shape.getSensor()) {
      return _shapeColor.withOpacity(.3);
    } else {
      var body = shape.getBody();
      if (body.isSleeping) {
        return Colors.blueGrey;
      } else if (body.sleeping.idleTime >
          shape.getSpace().getSleepTimeThreshold()) {
        return Colors.blueGrey.shade300;
      } else {
        return _shapeColor;
      }
    }
  }

  void _debugDrawDotFunc(Canvas canvas, double size, Vector2 pos, Color color) {
    canvas.save();
    canvas.drawCircle(
        Offset(pos.x, pos.y),
        size,
        Paint()
          ..color = color
          ..strokeWidth = 1
          ..style = PaintingStyle.fill);
    canvas.restore();
  }

  void _debugDrawFatSegmentFunc(Canvas canvas, Vector2 a, Vector2 b,
      double radius, Color outlineColor, Color fillColor) {
    canvas.save();

    canvas.drawLine(
        Offset(a.x, a.y),
        Offset(b.x, b.y),
        Paint()
          ..color = outlineColor
          ..strokeCap = StrokeCap.round
          ..strokeWidth = radius * 2
          ..strokeJoin = StrokeJoin.miter);
    canvas.restore();
  }

  void _debugDrawPolygonFunc(Canvas canvas, List<Vector2> verts, double radius,
      Color outlineColor, Color fillColor) {
    canvas.save();
    canvas.drawPath(
        _computePath([for (var ele in verts) Offset(ele.x, ele.y)], radius),
        Paint()
          ..style = PaintingStyle.fill
          ..color = fillColor);
    canvas.drawPath(
        _computePath([for (var ele in verts) Offset(ele.x, ele.y)], radius),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 2
          ..color = outlineColor);

    canvas.restore();
  }

  void _debugDrawSegmentFunc(Canvas canvas, Vector2 a, Vector2 b, Color color) {
    canvas.save();
    canvas.drawLine(
        Offset(a.x, a.y),
        Offset(b.x, b.y),
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.miter);
    canvas.restore();
  }

  Path _computePath(List<Offset> vertices, double radius) {
    final path = Path();
    final length = vertices.length;

    for (int i = 0; i <= length; i++) {
      final src = vertices[i % length];
      final dst = vertices[(i + 1) % length];

      final stepResult = __computeStep(src, dst, radius);
      final step = stepResult.point;
      final srcX = src.dx;
      final srcY = src.dy;
      final stepX = step.dx;
      final stepY = step.dy;

      if (i == 0) {
        path.moveTo(srcX + stepX, srcY + stepY);
      } else {
        path.quadraticBezierTo(srcX, srcY, srcX + stepX, srcY + stepY);
      }

      if (stepResult.drawSegment) {
        path.lineTo(dst.dx - stepX, dst.dy - stepY);
      }
    }

    return path;
  }

  _StepResult __computeStep(Offset a, Offset b, double radius) {
    Offset point = b - a;
    final dist = point.distance;
    if (dist <= radius * 2) {
      point *= 0.5;
      return _StepResult(false, point);
    } else {
      point *= radius / dist;
      return _StepResult(true, point);
    }
  }
}

class _StepResult {
  _StepResult(this.drawSegment, this.point);
  final bool drawSegment;
  final Offset point;
}
