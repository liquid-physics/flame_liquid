// ignore_for_file: unused_field

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

class Sticky extends StatefulWidget {
  static const route = '/sticky';

  const Sticky({super.key});

  @override
  State<Sticky> createState() => _StickyState();
}

class _StickyState extends State<Sticky> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      body: GameWidget(game: StickyGame()),
    );
  }
}

class StickyGame extends FlameGame with LiquidPhysics {
  final _random = Random();
  double next(double min, double max) =>
      min + _random.nextDouble() * (max - min);

  @override
  Future<void> onLoad() async {
    initializePhysics(
      initial: (space) => space
        ..setIternation(iterations: 10)
        ..setGravity(gravity: Vector2(0, 1000))
        ..setCollisionSlop(collisionSlop: 2),
    );
    camera.viewport.add(FpsTextComponent());
    camera.viewfinder.anchor = Anchor.topLeft;
    world.add(GrabberComponent());
    world.addAll(Boundaries.createBoundaries(size));
    world.add(LiquidDebugDraw(space));
    var mid = Vector2(size.x / 2, size.y / 2);

    for (var i = 0; i < 200; i++) {
      world.add(_Circle(
          Vector2(lerpDouble(-150, 150, _random.nextDouble()) ?? 0,
                      lerpDouble(-150, 150, _random.nextDouble()) ?? 0)
                  .flipY() +
              mid,
          10));
    }

    space.addWildcardHandler(type: 1)
      ..preSolve((arbiter, space) {
        // We want to fudge the collisions a bit to allow shapes to overlap more.
        // This simulates their squishy sticky surface, and more importantly
        // keeps them from separating and destroying the joint.

        // Track the deepest collision point and use that to determine if a rigid collision should occur.
        var deepest = double.infinity;

        // Grab the contact set and iterate over them.
        var contacts = arbiter.getContactPointSet();
        for (int i = 0; i < contacts.count; i++) {
          // Sink the contact points into the surface of each shape.
          contacts.points[i] = contacts.points[i].copyWith(
            pointA: contacts.points[i].pointA -
                (contacts.normal * _stickSensorThickness),
            pointB: contacts.points[i].pointB +
                (contacts.normal * _stickSensorThickness),
          );

          deepest = min(deepest, contacts.points[i].distance) +
              2 * _stickSensorThickness;
        }
        // Set the new contact point data.
        arbiter.setContactPointSet(contacts);
        // If the shapes are overlapping enough, then create a
        // joint that sticks them together at the first contact point.
        if (arbiter.getData<Constraint>() == null && deepest <= 0.0) {
          var (Body bodyA, Body bodyB) = arbiter.getBodies();

          // Create a joint at the contact point to hold the body in place.
          var anchorA = bodyA.worldToLocal(contacts.points[0].pointA);
          var anchorB = bodyB.worldToLocal(contacts.points[0].pointB);

          // Give it a finite force for the stickyness.
          var joint =
              PivotJoint(a: bodyA, b: bodyB, anchorA: anchorA, anchorB: anchorB)
                ..setMaxForce(3e3);

          //Schedule a post-step() callback to add the joint.
          space.addPostStepCallback<Constraint>(joint, (space, liquidType) {
            space.addConstraint(constraint: liquidType);
          });

          arbiter.setData<Constraint>(joint);
          //print(Called.count++);

          // Store the joint on the arbiter so we can remove it later.
        }
        // Position correction and velocity are handled separately so changing
        // the overlap distance alone won't prevent the collision from occuring.
        // Explicitly the collision for this frame if the shapes don't overlap using the new distance.
        return (deepest <= 0.0);

        // Lots more that you could improve upon here as well:
        // * Modify the joint over time to make it plastic.
        // * Modify the joint in the post-step to make it conditionally plastic (like clay).
        // * Track a joint for the deepest contact point instead of the first.
        // * Track a joint for each contact point. (more complicated since you only get one data pointer).
      })
      ..separate((arbiter, space) {
        var joint = arbiter.getData<Constraint>();

        if (joint != null) {
          // The joint won't be removed until the step is done.
          // Need to disable it so that it won't apply itself.
          // Setting the force to 0 will do just that
          joint.setMaxForce(0);

          // Perform the removal in a post-step() callback.
          space.addPostStepCallback<Constraint>(joint, (space, liquidType) {
            space.removeConstraint(constraint: liquidType);
          });
          arbiter.removeData();
        }
      });
  }
}

var _stickSensorThickness = 2.5;

class _Circle extends PositionComponent
    with LiquidPhysicsComponent, LiquidDynamicBody {
  final Vector2 _position;
  final double _radius;
  _Circle(this._position, this._radius) : super(position: _position);
  @override
  (Body, Shape) create() {
    var body = space.addBody(
        body: Body(
            mass: .15,
            moment: Moment.forCircle(.15, 0.0, _radius, Vector2.zero())))
      ..setPosition(pos: position);

    var shape = space.addShape(
        shape: CircleShape(
            body: body,
            radius: _radius + _stickSensorThickness,
            offset: Vector2.zero()))
      ..setFriction(.9)
      ..setCollisionType(1);
    return (body, shape);
  }
}
