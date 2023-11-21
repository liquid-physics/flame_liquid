import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:example/helper/boundaries.dart';
import 'package:example/helper/grabber.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flame_liquid/flame_liquid.dart';
import 'package:example/helper/common.dart';

class Plinks extends StatefulWidget {
  static const route = '/plinks';

  const Plinks({super.key});

  @override
  State<Plinks> createState() => _PlinksState();
}

class _PlinksState extends State<Plinks> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      body: GameWidget(game: PlinksGame()),
    );
  }
}

class PlinksGame extends FlameGame with LiquidPhysics, SecondaryTapDetector {
  final world = World();
  late final CameraComponent cameraComponent;

  final _random = Random();
  double next(double min, double max) =>
      min + _random.nextDouble() * (max - min);

  @override
  void onSecondaryTapDown(TapDownInfo info) {
    super.onSecondaryTapDown(info);
    var (Shape sh, _) = space.pointQueryNearest(
        mouse: info.eventPosition.game, radius: 0, filter: grabFilter);
    if (sh.isExist) {
      Body body = sh.getBody();
      if (body.getType() == BodyType.static) {
        body.setType(BodyType.dynamic);
        body.setMass(_Pentagon.mass);
        body.setMoment(_Pentagon.moment);
      } else if (body.getType() == BodyType.dynamic) {
        body.setType(BodyType.static);
      }
    }
  }

  @override
  void fixedUpdate(double timeStep) {
    super.fixedUpdate(timeStep);

    space.eachBody((body) {
      Vector2 pos = (body).getPosition();

      if (pos.y > size.y - 10 ||
          pos.x > size.x / 2 + 340 ||
          pos.x < size.x / 2 - 340) {
        body.setPosition(
            pos: Vector2(next(-320 + size.x / 2, 320 + size.x / 2), -10));
      }
    });
  }

  @override
  Future<void> onLoad() async {
    initializePhysics();
    cameraComponent = CameraComponent(world: world)
      ..viewport.add(FpsTextComponent())
      ..viewfinder.anchor = Anchor.topLeft;

    addAll([cameraComponent, world]);
    world.add(GrabberComponent());
    world.addAll(Boundaries.createBoundaries(size));

    for (int i = 0; i < 300; i++) {
      world.add(_Pentagon(
          Vector2(next(-320 + size.x / 2, 320 + size.x / 2), -100),
          Color((_random.nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0)));
    }

    world.addAll([
      for (var i = 0; i < 9; i++)
        for (var j = 0; j < 9; j++) ...[
          _Triangle(
            Vector2((i * 80 - 320 + (j % 2) * 40) + size.x / 2,
                -(j * 70 - 240) + size.y / 2),
            Color((_random.nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0),
          )
        ]
    ]);
  }
}

class _Triangle extends PositionComponent
    with LiquidPhysicsComponent, LiquidStaticBody {
  final Vector2 pos;
  final Color color;

  _Triangle(this.pos, this.color) : super(position: pos);
  final _triangle = <Vector2>[
    Vector2(-15, 15),
    Vector2(0, -10),
    Vector2(15, 15),
  ];
  @override
  void create() {
    space.addShape(
        shape: PolyShape(
            body: space.getStaticBody(),
            vert: _triangle,
            transform: Matrix4.identity()..translate(pos.x, pos.y),
            radius: 0.0))
      ..setElasticity(1)
      ..setFriction(1)
      ..setFilter(notGrabbableFilter);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.save();
    canvas.drawVertices(
        Vertices(VertexMode.triangles, [
          for (var ele in _triangle)
            Offset(ele.x, ele.y) - transform.offset.toOffset()
        ]),
        BlendMode.dst,
        Paint()
          ..style = PaintingStyle.fill
          ..color = color);
    canvas.restore();
  }
}

class _Pentagon extends PositionComponent
    with TapCallbacks, LiquidPhysicsComponent, LiquidDynamicBody {
  final Vector2 pos;
  final Color color;
  _Pentagon(this.pos, this.color);
  static final _pentagon = <Vector2>[
    for (int i = 0; i < 5; i++)
      Vector2(10 * cos(-2.0 * pi * i / 5), 10 * sin(-2.0 * pi * i / 5)),
  ];
  static double mass = 1;
  static double moment = Moment.forPoly(1, _pentagon, Vector2.zero(), 0);
  final _random = Random();
  double next(double min, double max) =>
      min + _random.nextDouble() * (max - min);
  @override
  (Body, Shape) create() {
    var body = space.addBody(body: Body(mass: mass, moment: moment))
      ..setPosition(pos: pos);

    var shape = space.addShape(
        shape: PolyShape(
            body: body,
            vert: _pentagon,
            transform: Matrix4.identity(),
            radius: 0))
      ..setElasticity(0)
      ..setFriction(0.4);

    return (body, shape);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.save();

    canvas.drawVertices(
        Vertices(VertexMode.triangleFan, [
          for (var ele in _pentagon)
            Offset(ele.x, ele.y) - transform.offset.toOffset()
        ]),
        BlendMode.dst,
        Paint()
          ..style = PaintingStyle.fill
          ..color = color);
    canvas.restore();
  }
}
