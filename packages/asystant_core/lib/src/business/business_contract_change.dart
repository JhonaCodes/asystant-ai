import 'package:asystant_core/src/business/business_contract.dart';
import 'package:asystant_core/src/business/business_endpoint.dart';
import 'package:asystant_core/src/business/business_environment.dart';

/// What a new version of a contract invalidates of the sessions saved for
/// the previous one.
extension BusinessContractChange on BusinessContract {
  /// The environments whose saved sessions no longer apply once this
  /// contract replaces [previous].
  ///
  /// A session is bound to how it was obtained: it is reset when the base
  /// URL or the sign-in flow changed, and kept when only public or private
  /// headers or profile labels did. [signedIn] is the environment that has
  /// just signed in with this contract's parameters: a change of only its
  /// sign-in parameters keeps that fresh session.
  List<BusinessEnvironment> sessionResetsFrom(
    BusinessContract? previous, {
    BusinessEnvironment? signedIn,
  }) => [
    for (final environment in BusinessEnvironment.values)
      if (_signsInDifferently(
        previous?.endpoint(environment),
        endpoint(environment),
        keepsParameters: environment == signedIn,
      ))
        environment,
  ];

  /// The private headers [previous] declared for [environment] (on the
  /// endpoint or any operation) that this contract no longer declares, in
  /// lower case: their saved values can be deleted.
  Set<String> droppedPrivateHeaders(
    BusinessContract? previous,
    BusinessEnvironment environment,
  ) => previous == null
      ? const {}
      : previous
            ._privateHeaderNames(environment)
            .difference(_privateHeaderNames(environment));

  /// Every credential profile id of [environment] in this contract or in
  /// [previous]: those whose sessions a reset clears.
  Set<String> profileIdsWith(
    BusinessContract? previous,
    BusinessEnvironment environment,
  ) => {
    for (final contract in [?previous, this])
      ...?contract
          .endpoint(environment)
          ?.credentialProfiles
          .map((profile) => profile.id),
  };

  Set<String> _privateHeaderNames(BusinessEnvironment environment) => {
    for (final name
        in endpoint(environment)?.privateHeaders ?? const <String>[])
      name.toLowerCase(),
    for (final operation in operations)
      for (final name in operation.privateHeaders) name.toLowerCase(),
  };

  static bool _signsInDifferently(
    BusinessEndpoint? previous,
    BusinessEndpoint? next, {
    required bool keepsParameters,
  }) {
    if (previous == null || next == null) return previous != next;
    return previous.copyWith(
          headers: next.headers,
          privateHeaders: next.privateHeaders,
          profiles: next.profiles,
          auth: previous.auth.copyWith(
            headers: next.auth.headers,
            parameters: keepsParameters ? next.auth.parameters : null,
          ),
        ) !=
        next;
  }
}
