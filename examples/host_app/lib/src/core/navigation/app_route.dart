import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:host_app/src/core/navigation/app_shell.dart';
import 'package:host_app/src/core/navigation/route_screen.dart';
import 'package:host_app/src/modules/assessment/ui/screen/assessment_detail_screen.dart';
import 'package:host_app/src/modules/assessment/ui/screen/assessment_list_screen.dart';
import 'package:host_app/src/modules/home/ui/screen/home_screen.dart';
import 'package:host_app/src/modules/plant/ui/screen/plant_catalog_screen.dart';
import 'package:host_app/src/modules/plant/ui/screen/plant_detail_screen.dart';
import 'package:host_app/src/modules/profile/ui/screen/profile_screen.dart';
import 'package:host_app/src/modules/recommendation/ui/screen/recommendation_screen.dart';

/// Tabs live in the shell; detail pages open above it.
mixin AppRoute {
  static final _root = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _root,
    initialLocation: RouteScreen.home.path,
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: RouteScreen.home.path,
            pageBuilder: (_, _) => const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: RouteScreen.assessments.path,
            pageBuilder: (_, _) =>
                const NoTransitionPage(child: AssessmentListScreen()),
          ),
          GoRoute(
            path: RouteScreen.plants.path,
            pageBuilder: (_, _) =>
                const NoTransitionPage(child: PlantCatalogScreen()),
          ),
          GoRoute(
            path: RouteScreen.profile.path,
            pageBuilder: (_, _) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _root,
        path: RouteScreen.assessmentDetail.path,
        builder: (_, state) => AssessmentDetailScreen(
          assessmentId: state.pathParameters['assessmentId'] ?? '',
        ),
      ),
      GoRoute(
        parentNavigatorKey: _root,
        path: RouteScreen.recommendation.path,
        builder: (_, state) => RecommendationScreen(
          assessmentId: state.pathParameters['assessmentId'] ?? '',
        ),
      ),
      GoRoute(
        parentNavigatorKey: _root,
        path: RouteScreen.plantDetail.path,
        builder: (_, state) =>
            PlantDetailScreen(plantId: state.pathParameters['plantId'] ?? ''),
      ),
    ],
  );
}
