import 'package:flutter/foundation.dart';

/// How far one turn of the person may go before the chat stops it.
///
/// A turn is everything between the person's message and the assistant's
/// final answer: each inference round may propose tool calls, the chat runs
/// them and asks the model again. The limits apply the same way to every
/// provider, because the chat enforces them, not the transport.
///
/// ```dart
/// const AsystantTurnLimits()                  // 8 rounds, 16 calls
/// const AsystantTurnLimits(maxRounds: 20)     // a longer tool loop
/// ```
///
/// - When a turn uses its [maxRounds] and the last one still proposed tool
///   calls, those calls have run and their results are in the conversation,
///   but the model is not asked again: the turn ends with a
///   `FailureCode.limit` failure, shown in the chat.
/// - A response with more than [maxCallsPerResponse] calls is refused as a
///   `FailureCode.protocol` failure: none of its calls run and it is not
///   added to the conversation.
@immutable
class AsystantTurnLimits {
  const AsystantTurnLimits({this.maxRounds = 8, this.maxCallsPerResponse = 16});

  factory AsystantTurnLimits.fromJson(Map<String, Object?> json) =>
      AsystantTurnLimits(
        maxRounds: json['maxRounds'] as int,
        maxCallsPerResponse: json['maxCallsPerResponse'] as int,
      );

  /// The highest [maxRounds] accepted, so a host mistake cannot leave a
  /// turn calling the model without end.
  static const int maxRoundsCeiling = 64;

  /// The highest [maxCallsPerResponse] accepted: the built-in transports
  /// never deliver more than 16 calls in one response (a longer one is a
  /// protocol failure), so a higher value would promise nothing.
  static const int maxCallsCeiling = 16;

  /// Inference rounds in one turn, from 1 to [maxRoundsCeiling].
  final int maxRounds;

  /// Tool calls accepted in one model response, from 1 to [maxCallsCeiling].
  final int maxCallsPerResponse;

  /// Throws a [RangeError] when a value is outside its range.
  void validate() {
    RangeError.checkValueInInterval(
      maxRounds,
      1,
      maxRoundsCeiling,
      'maxRounds',
    );
    RangeError.checkValueInInterval(
      maxCallsPerResponse,
      1,
      maxCallsCeiling,
      'maxCallsPerResponse',
    );
  }

  AsystantTurnLimits copyWith({int? maxRounds, int? maxCallsPerResponse}) =>
      AsystantTurnLimits(
        maxRounds: maxRounds ?? this.maxRounds,
        maxCallsPerResponse: maxCallsPerResponse ?? this.maxCallsPerResponse,
      );

  Map<String, Object?> toJson() => {
    'maxRounds': maxRounds,
    'maxCallsPerResponse': maxCallsPerResponse,
  };

  @override
  bool operator ==(Object other) =>
      other is AsystantTurnLimits &&
      maxRounds == other.maxRounds &&
      maxCallsPerResponse == other.maxCallsPerResponse;

  @override
  int get hashCode => Object.hash(maxRounds, maxCallsPerResponse);

  @override
  String toString() =>
      'AsystantTurnLimits(maxRounds: $maxRounds, '
      'maxCallsPerResponse: $maxCallsPerResponse)';
}
