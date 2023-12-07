import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:example/helper/boundaries.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flame_liquid/flame_liquid.dart';
import 'package:example/helper/common.dart';

class Query extends StatefulWidget {
  static const route = '/query';

  const Query({super.key});

  @override
  State<Query> createState() => _QueryState();
}

class _QueryState extends State<Query> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      body: GameWidget(game: QueryGame()),
    );
  }
}

class QueryGame extends FlameGame
    with
        LiquidPhysics,
        SecondaryTapDetector,
        MouseMovementDetector,
        DragCallbacks {
  final world = World();
  late final CameraComponent cameraComponent;

  final _random = Random();
  double next(double min, double max) =>
      min + _random.nextDouble() * (max - min);

  var mid = Vector2.zero();

  @override
  Future<void> onLoad() async {
    initializePhysics(
      initial: (space) => space..setIternation(iterations: 5),
    );
    cameraComponent = CameraComponent(world: world)
      ..viewport.add(FpsTextComponent())
      ..viewfinder.anchor = Anchor.topLeft;
    mid = Vector2(size.x / 2, size.y / 2);
    start = mid;
    addAll([cameraComponent, world]);
    world.add(LiquidDebugDraw(space));
    world.addAll(Boundaries.createBoundaries(size));

    world.add(_Segment());
    world.add(_Static());
    world.add(_Pentagon());
    world.add(_Circle());
  }

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
    lineDraw = true;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    mouse = event.localPosition;
    event.continuePropagation;
    end = event.localPosition;
  }

  var start = Vector2.zero();
  var end = Vector2.zero();
  var lineDraw = true;
  var lineDraw1 = false;
  Vector2 poi = Vector2.zero();
  Vector2 nor = Vector2.zero();
  double alp = 0;
  var desc = '';

  @override
  void fixedUpdate(double timeStep) {
    super.fixedUpdate(timeStep);
    var newPoint = Vector2(lerpDouble(mouseBody.p.x, mouse.x, 1) ?? 0,
        lerpDouble(mouseBody.p.y, mouse.y, 1) ?? 0);
    mouseBody.v = (newPoint - mouseBody.p) * 60;
    mouseBody.p = newPoint;

    var (shape, info) = space.segmentQueryFirst(
        start: start, end: end, radius: 10, filter: shapeFilterAll);
    if (shape.isExist) {
      poi = info.point;
      nor = info.normal;
      alp = info.alpha;
      lineDraw1 = true;
      desc =
          'Segment Query: Dist(${alp * (end - start).length}) Normal(${nor.x}, ${nor.y})';
    } else {
      lineDraw1 = false;
      alp = 1;
      desc = 'Segment Query (None)';
    }
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

  TextPaint textPaint = TextPaint(
    style: const TextStyle(
      fontSize: 15.0,
      fontFamily: 'Awesome Font',
    ),
  );

  @override
  void onSecondaryTapDown(TapDownInfo info) {
    super.onSecondaryTapDown(info);
    start = info.eventPosition.global;
    lineDraw = false;
  }

  @override
  void onSecondaryTapUp(TapUpInfo info) {
    super.onSecondaryTapUp(info);
    lineDraw = true;
  }

  @override
  void onMouseMove(PointerHoverInfo info) {
    super.onMouseMove(info);
    end = info.eventPosition.global;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    textPaint.render(
        canvas,
        'Query: Distance (${(end - start).length}) Point (${end.x} ${end.y}) $desc',
        Vector2(10, size.y),
        anchor: Anchor.bottomLeft);
    canvas.drawLine(
        start.toOffset(),
        Vector2(_lerpDouble(start.x, end.x, alp),
                _lerpDouble(start.y, end.y, alp))
            .toOffset(),
        Paint()
          ..color = Colors.yellowAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 20
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.miter);
    if (lineDraw) {
      canvas.drawLine(
          start.toOffset(),
          end.toOffset(),
          Paint()
            ..color = Colors.greenAccent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.miter);
    }
    if (lineDraw1) {
      canvas.drawLine(
          Vector2(_lerpDouble(start.x, end.x, alp),
                  _lerpDouble(start.y, end.y, alp))
              .toOffset(),
          end.toOffset(),
          Paint()
            ..color = Colors.blue
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.miter);
      canvas.drawLine(
          poi.toOffset(),
          (poi + (nor * 16)).toOffset(),
          Paint()
            ..color = Colors.red
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.miter);
    }
  }

  double _lerpDouble(double a, double b, double t) {
    return a * (1.0 - t) + b * t;
  }
}

class _Segment extends PositionComponent
    with LiquidPhysicsComponent, LiquidDynamicBody, HasGameRef<QueryGame> {
  static const double mass = 1;
  static const double length = 100;
  var a = Vector2(-length / 2, 0);
  var b = Vector2(length / 2, 0);
  @override
  (Body, Shape) create() {
    var body = space.addBody(
        body: Body(mass: mass, moment: Moment.forSegment(mass, a, b, 0)))
      ..setPosition(pos: Vector2(0, 100).flipY() + game.mid);
    var shape =
        space.addShape(shape: SegmentShape(body: body, a: a, b: b, radius: 20));

    return (body, shape);
  }
}

class _Static extends PositionComponent
    with LiquidPhysicsComponent, LiquidStaticBody, HasGameRef<QueryGame> {
  var a = Vector2(0, 300).flipY();
  var b = Vector2(300, 0).flipY();
  @override
  void create() {
    space.addShape(
        shape: SegmentShape(
            body: space.getStaticBody(),
            a: a + game.mid,
            b: b + game.mid,
            radius: 1));
  }
}

class _Pentagon extends PositionComponent
    with LiquidPhysicsComponent, LiquidDynamicBody, HasGameRef<QueryGame> {
  static final _pentagon = <Vector2>[
    for (int i = 0; i < 5; i++)
      Vector2(30 * cos(-2.0 * pi * i / 5), 30 * sin(-2.0 * pi * i / 5)),
  ];
  static double mass = 1;
  static double moment = Moment.forPoly(1, _pentagon, Vector2.zero(), 0);
  @override
  (Body, Shape) create() {
    var body = space.addBody(body: Body(mass: mass, moment: moment))
      ..setPosition(pos: Vector2(50, 30).flipY() + game.mid);

    var shape = space.addShape(
        shape: PolyShape(
            body: body,
            vert: _pentagon,
            transform: Matrix4.identity(),
            radius: 10));

    return (body, shape);
  }
}

class _Circle extends PositionComponent
    with LiquidPhysicsComponent, LiquidDynamicBody, HasGameRef<QueryGame> {
  var radius = 20.0;
  @override
  (Body, Shape) create() {
    var body = space.addBody(
        body: Body(
            mass: 1.0,
            moment: Moment.forCircle(1.0, radius, 0, Vector2.zero())))
      ..setPosition(pos: Vector2(100, 100).flipY() + game.mid);
    var shape = space.addShape(
        shape: CircleShape(body: body, radius: radius, offset: Vector2.zero()));
    return (body, shape);
  }
}
