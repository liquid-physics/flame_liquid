import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:example/helper/boundaries.dart';
import 'package:example/helper/grabber.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flame_liquid/flame_liquid.dart';
import 'package:example/helper/common.dart';

class Planet extends StatefulWidget {
  static const route = '/planet';

  const Planet({super.key});

  @override
  State<Planet> createState() => _PlanetState();
}

class _PlanetState extends State<Planet> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      body: GameWidget(game: PlanetGame()),
    );
  }
}

class PlanetGame extends FlameGame with LiquidPhysics {
  final world = World();
  late final CameraComponent cameraComponent;

  final _random = Random();
  double next(double min, double max) =>
      min + _random.nextDouble() * (max - min);

  // @override
  // bool get renderDebug => true;

  @override
  Future<void> onLoad() async {
    initializePhysics(
      initial: (space) {
        return space..setIternation(iterations: 20);
      },
    );
    cameraComponent = CameraComponent(world: world)
      ..viewport.add(FpsTextComponent())
      ..viewfinder.anchor = Anchor.topLeft;
    cameraComponent.viewfinder.zoom = .8;
    addAll([cameraComponent, world]);
    world.add(GrabberComponent());
    world.add(LiquidDebugDraw(space));
    world.addAll(Boundaries.createBoundaries(size));

    world.add(_Planet(Vector2(size.x / 2, size.y / 2), 70));

    for (var i = 0; i < 30; i++) {
      world.add(_Asteroid(randPos(10), Vector2(size.x / 2, size.y / 2)));
    }
  }

  Vector2 randPos(double radius) {
    var v = Vector2.zero();
    do {
      v = Vector2(_random.nextDouble() * (640 - 2 * radius) - (320 - radius),
              _random.nextDouble() * (480 - 2 * radius) - (240 - radius)) +
          Vector2(size.x / 2, size.y / 2);
    } while (v.length < 85);
    return v;
  }
}

class _Planet extends PositionComponent
    with LiquidPhysicsComponent, LiquidKinematicBody {
  final Vector2 pos;
  final double radius;
  _Planet(this.pos, this.radius) : super(position: pos);
  late Body body;

  @override
  void create() {
    body = space.addBody(body: KinematicBody())
      ..setAngularVelocity(.2)
      ..setPosition(pos: pos);

    space.addShape(
        shape: CircleShape(body: body, radius: radius, offset: Vector2.zero()))
      ..setElasticity(1)
      ..setFriction(1)
      ..setFilter(notGrabbableFilter);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.save();
    rotate(canvas: canvas, cx: 0, cy: 0, angle: body.getAngle());
    canvas.drawCircle(Offset.zero, radius, Paint()..color = Colors.purple);
    canvas.drawLine(
        Offset.zero, const Offset(50, 0), Paint()..color = Colors.white);
    canvas.restore();
  }

  void rotate(
      {required Canvas canvas,
      required double cx,
      required double cy,
      required double angle}) {
    canvas.translate(cx, cy);
    canvas.rotate(angle);
    canvas.translate(-cx, -cy);
  }
}

class _Asteroid extends PositionComponent
    with LiquidPhysicsComponent, LiquidDynamicBody {
  final double gravityStrength = 5.0e6;
  final Vector2 pos;
  static double sizeV = 10;
  final Vector2 mid;
  double mass = 4;
  final verts = <Vector2>[
    Vector2(-sizeV, -sizeV),
    Vector2(-sizeV, sizeV),
    Vector2(sizeV, sizeV),
    Vector2(sizeV, -sizeV),
  ];

  _Asteroid(this.pos, this.mid) : super(position: pos);

  @override
  (Body, Shape) create() {
    var mm = Moment.forPoly(mass, verts, Vector2.zero(), 0);
    var body = space.addBody(body: Body(mass: mass, moment: mm))
      ..setVelocityUpdateFunc((bodys, gravity, damping, dt) {
        var p = bodys.getPosition() - mid;
        var sqdist = p.dot(p);
        var g = p * (-gravityStrength / (sqdist * sqrt(sqdist)));
        bodys.updateVelocity(gravity: g, damping: damping, dt: dt);
      })
      ..setPosition(pos: pos);

    double r = (pos - mid).length;
    double v = sqrt(gravityStrength / r) / r;
    body
      ..setVelocity(vel: Vector2(-(pos - mid).y, (pos - mid).x) * v)
      ..setAngularVelocity(v)
      ..setAngle(atan2((pos - mid).y, (pos - mid).x));

    var shape = space.addShape(
        shape: PolyShape(
            body: body,
            vert: verts,
            transform: Matrix4.identity(),
            radius: 0.0))
      ..setElasticity(0)
      ..setFriction(.7);

    return (body, shape);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.save();
    canvas.drawVertices(
        Vertices(VertexMode.triangleFan, [
          for (var ele in verts)
            Offset(ele.x, ele.y) - transform.offset.toOffset()
        ]),
        BlendMode.dst,
        Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.redAccent);
    canvas.restore();
  }
}
