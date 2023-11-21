

import 'package:flame/components.dart';
import 'package:flame_liquid/flame_liquid.dart';

class Boundaries {
  
  static List<Component> createBoundaries(Vector2 size) {
    final topLeft = Vector2.zero();
    final bottomRight = Vector2(size.x, size.y);
    final topRight = Vector2(size.x, 0);
    final bottomLeft = Vector2(0, size.y);

    return [
      Wall(topRight, bottomRight),
      Wall(bottomLeft, bottomRight),
      Wall(topLeft, bottomLeft),
    ];
  }
}


class Wall extends PositionComponent
    with LiquidPhysicsComponent, LiquidStaticBody {
  final Vector2 _start;
  final Vector2 _end;

  Wall(this._start, this._end);

  @override
  void create() {
    var staticBody = space.getStaticBody();
    space.addShape(
        shape: SegmentShape(body: staticBody, a: _start, b: _end, radius: 0))
      ..setElasticity(1)
      ..setFriction(1)
      ..setFilter(notGrabbableFilter);
  }
}