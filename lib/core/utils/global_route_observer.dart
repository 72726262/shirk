import 'package:flutter/material.dart';

class GlobalRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  static String? currentRouteName;
  static Object? currentRouteArgs;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PageRoute) {
      currentRouteName = route.settings.name;
      currentRouteArgs = route.settings.arguments;
      print('🔀 Navigation PUSH: $currentRouteName');
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute is PageRoute) {
      currentRouteName = newRoute.settings.name;
      currentRouteArgs = newRoute.settings.arguments;
      print('🔀 Navigation REPLACE: $currentRouteName');
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute is PageRoute && route is PageRoute) {
      currentRouteName = previousRoute.settings.name;
      currentRouteArgs = previousRoute.settings.arguments;
      print('🔀 Navigation POP: $currentRouteName');
    }
  }
}
