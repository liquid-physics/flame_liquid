import 'package:flutter/material.dart';

class FadePageRoute<T> extends MaterialPageRoute<T> {
  FadePageRoute(
      {required WidgetBuilder builder, required RouteSettings settings})
      : super(builder: builder, settings: settings);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}

class FadePageTransitionBuilder extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T>(
      PageRoute<T> route,
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    //if (route.settings.name == MyApp.routeHome) return child;

    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}
