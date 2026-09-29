/// Every route of the app.
enum RouteScreen {
  home('/'),
  assessments('/assessments'),
  assessmentDetail('/assessments/:assessmentId'),
  recommendation('/assessments/:assessmentId/recommendation'),
  plants('/plants'),
  plantDetail('/plants/:plantId'),
  profile('/profile');

  const RouteScreen(this.path);

  final String path;

  static final _parameter = RegExp(r':\w+');

  /// The path with its parameter filled, e.g. `/plants/manzanilla`.
  String pathFor(String id) => path.replaceFirst(_parameter, id);
}

/// The four tabs, in order.
enum ShellTab {
  home(RouteScreen.home),
  assessments(RouteScreen.assessments),
  plants(RouteScreen.plants),
  profile(RouteScreen.profile);

  const ShellTab(this.route);

  final RouteScreen route;

  /// The tab a location belongs to.
  static ShellTab fromLocation(String location) => switch (location) {
    final path when path.startsWith(RouteScreen.assessments.path) =>
      ShellTab.assessments,
    final path when path.startsWith(RouteScreen.plants.path) => ShellTab.plants,
    final path when path.startsWith(RouteScreen.profile.path) =>
      ShellTab.profile,
    _ => ShellTab.home,
  };
}
