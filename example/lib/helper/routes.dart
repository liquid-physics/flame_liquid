import 'package:example/ball_fall/ball_fall.dart';
import 'package:example/bouncy_hexagon/bouncy_hexagon.dart';
import 'package:example/buoyancy/buoyancy.dart';
import 'package:example/chain/chain.dart';
import 'package:example/contact_graph/contact_graph.dart';
import 'package:example/convex/convex.dart';
import 'package:example/crane/crane.dart';
import 'package:example/helper/fade_page.dart';
import 'package:example/joint/joint.dart';
import 'package:example/logo_smash/logo_smash.dart';
import 'package:example/one_way/one_way.dart';
import 'package:example/planet/planet.dart';
import 'package:example/player/player.dart';
import 'package:example/plinks/plinks.dart';
import 'package:example/pump/pump.dart';
import 'package:example/pyramid_stack/pyramid_stack.dart';
import 'package:example/pyramid_topple/pyramid_topple.dart';
import 'package:example/query/query.dart';
import 'package:example/shatter/shatter.dart';
import 'package:example/slice/slice.dart';
import 'package:example/springies/springies.dart';
import 'package:example/sticky/sticky.dart';
import 'package:example/tank/tank.dart';
import 'package:example/theo_jansen/theo_jansen.dart';
import 'package:example/tumble/tumble.dart';
import 'package:example/unicycle/unicycle.dart';
import 'package:flutter/material.dart';

var routes = <String, (Widget, String)>{
  BallFall.route: (const BallFall(), 'A. Ball Fall'),
  LogoSmash.route: (const LogoSmash(), 'B. Logo Smash'),
  PyramidStack.route: (const PyramidStack(), 'C. Pyramid Stack'),
  Plinks.route: (const Plinks(), 'D. Plink'),
  BouncyHexagon.route: (const BouncyHexagon(), 'E. Bouncy Hexagon'),
  Tumble.route: (const Tumble(), 'F. Tumble'),
  PyramidTopple.route: (const PyramidTopple(), 'G. Pyramid Topple'),
  Planet.route: (const Planet(), 'H. Planet'),
  Springies.route: (const Springies(), 'I. Springies'),
  Pump.route: (const Pump(), 'J. Pump'),
  TheoJansen.route: (const TheoJansen(), 'K. Theo Jansen'),
  Query.route: (const Query(), 'L. Query'),
  OneWay.route: (const OneWay(), 'M. One Way'),
  Joint.route: (const Joint(), 'N. Joint and Constraint'),
  Tank.route: (const Tank(), 'O. Tank'),
  Chain.route: (const Chain(), 'P. Chain'),
  Crane.route: (const Crane(), 'Q. Crane'),
  ContactGraph.route: (const ContactGraph(), 'R. Contact Graph'),
  Buoyancy.route: (const Buoyancy(), 'S. Buoyancy'),
  Player.route: (const Player(), 'T. Player'),
  Slice.route: (const Slice(), 'U. Slice'),
  Convex.route: (const Convex(), 'V. Convex'),
  Unicycle.route: (const Unicycle(), 'W. Unicycle'),
  Sticky.route: (const Sticky(), 'X. Sticky'),
  Shatter.route: (const Shatter(), 'Y. Shatter'),
};

var index = 0;

void next() => index++;
void prev() => index--;

var routeGen = (RouteSettings settings, BuildContext context) {
  if (settings.name == routes.entries.elementAt(index % routes.length).key) {
    return FadePageRoute(
        builder: (context) =>
            routes.entries.elementAt(index % routes.length).value.$1,
        settings: settings);
  }
};
