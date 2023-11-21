import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_liquid/flame_liquid.dart';

class GrabberComponent extends PositionComponent
    with LiquidPhysicsComponent, LiquidKinematicBody, DragCallbacks {
  Vector2 mouse = Vector2.zero();
  PivotJoint? mouseJoint;
  Body mouseBody = KinematicBody();

  @override
  bool containsLocalPoint(Vector2 point) {
    super.containsLocalPoint(point);
    return true;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (mouseJoint != null) {
      space.removeConstraint(constraint: mouseJoint!);
      mouseJoint!.destroy();
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    mouse = event.localPosition;
    event.continuePropagation;
  }

  @override
  void fixedUpdate(double timeStep) {
    super.fixedUpdate(timeStep);
    var newPoint = Vector2(lerpDouble(mouseBody.p.x, mouse.x, 1) ?? 0,
        lerpDouble(mouseBody.p.y, mouse.y, 1) ?? 0);
    mouseBody.v = (newPoint - mouseBody.p) * 60;
    mouseBody.p = newPoint;
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    var (Shape sh, PointQueryInfo pq) = space.pointQueryNearest(
        mouse: event.localPosition, radius: 0, filter: grabFilter);

    if (sh.isExist) {
      if (sh.getBody().getMass() < double.infinity) {
        Vector2 nearest = (pq.distance > 0 ? pq.point : event.localPosition);

        var body = sh.getBody();
        mouseJoint = PivotJoint(
            a: mouseBody,
            b: body,
            anchorA: Vector2.zero(),
            anchorB: body.worldToLocal(nearest))
          ..maxForce = 50000
          ..errorBias = pow(1 - .15, 60).toDouble();

        space.addConstraint(constraint: mouseJoint!);
      }
    }
  }

  @override
  void create() {}
}
