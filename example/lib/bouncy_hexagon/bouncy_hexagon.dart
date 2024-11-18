import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:example/bouncy_hexagon/terrrain_data.dart';
import 'package:example/helper/boundaries.dart';
import 'package:example/helper/grabber.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flame_liquid/flame_liquid.dart';
import 'package:example/helper/common.dart';

class BouncyHexagon extends StatefulWidget {
  static const route = '/bouncy-hexagon';

  const BouncyHexagon({super.key});

  @override
  State<BouncyHexagon> createState() => _BouncyHexagonState();
}

class _BouncyHexagonState extends State<BouncyHexagon> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      body: GameWidget(game: BouncyHexagonGame()),
    );
  }
}

class BouncyHexagonGame extends FlameGame with LiquidPhysics {
  late final CameraComponent cameraComponent;

  final _random = Random();
  double next(double min, double max) =>
      min + _random.nextDouble() * (max - min);

  @override
  Future<void> onLoad() async {
    initializePhysics(
      initial: (space) {
        return space..setIternation(iterations: 10);
      },
    );
    camera.viewport.add(FpsTextComponent());
    camera.viewfinder.anchor = Anchor.topLeft;

    world.add(GrabberComponent());
    world.addAll(Boundaries.createBoundaries(size));

    var offset = Vector2(-320 + size.x / 2, -240 + size.y / 2);

    for (var i = 0; i < terrainData.length - 1; i++) {
      world.add(_Terrain(terrainData[i] + offset, terrainData[i + 1] + offset));
    }

    for (var i = 0; i < 500; i++) {
      world.add(_Hexagon(
          Color((_random.nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0),
          Vector2(size.x / 2, size.y / 2)));
    }
  }
}

class _Terrain extends PositionComponent
    with LiquidPhysicsComponent, LiquidStaticBody {
  final Vector2 a;
  final Vector2 b;
  _Terrain(this.a, this.b);

  @override
  void create() {
    space
        .addShape(
            shape: SegmentShape(
                body: space.getStaticBody(), a: a, b: b, radius: 0))
        .setElasticity(1);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.save();
    canvas.drawLine(
        Offset(a.x, a.y) - transform.offset.toOffset(),
        Offset(b.x, b.y) - transform.offset.toOffset(),
        Paint()
          ..color = Colors.white
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 1);
    canvas.restore();
  }
}

class _Hexagon extends PositionComponent
    with LiquidPhysicsComponent, LiquidDynamicBody {
  final Color color;
  final Vector2 mid;
  _Hexagon(this.color, this.mid);
  final _random = Random();
  double next(double min, double max) =>
      min + _random.nextDouble() * (max - min);
  static final _hexagon = <Vector2>[
    for (int i = 0; i < 6; i++)
      Vector2(cos(-pi * 2.0 * i / 6.0), sin(-pi * 2.0 * i / 6.0)) * (5 - 1),
  ];
  static double moment =
      Moment.forPoly(radius * radius, _hexagon, Vector2.zero(), 0);
  static double radius = 5;
  @override
  (Body, Shape) create() {
    var body = space.addBody(body: Body(mass: radius * radius, moment: moment))
      ..setPosition(pos: Vector2(next(-1, 1), next(-1, 1)) * 130 + mid)
      ..setVelocity(vel: Vector2(next(0, 1), next(0, 1)) * 50);

    var shape = space.addShape(
        shape: PolyShape(
            body: body,
            vert: _hexagon,
            transform: Matrix4.identity(),
            radius: 1))
      ..setElasticity(1);

    return (body, shape);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.save();
    canvas.drawVertices(
        Vertices(VertexMode.triangleFan, [
          for (var ele in _hexagon)
            Offset(ele.x, ele.y) - transform.offset.toOffset()
        ]),
        BlendMode.dst,
        Paint()
          ..style = PaintingStyle.fill
          ..color = color);
    canvas.restore();
  }
}
