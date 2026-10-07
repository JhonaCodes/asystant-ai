/// SDK-wide limits shared by every transport, so OpenRouter and Claude Code
/// cannot silently diverge on what the protocol allows.
abstract final class AsystantSdkLimits {
  /// Tool calls accepted in a single model turn.
  static const int maxToolCalls = 16;

  /// Longest serialized arguments accepted for one tool call, in bytes.
  static const int maxArgumentsLength = 64 * 1024;

  /// Longest text taken from one attached text file, in characters.
  static const int maxAttachmentText = 60000;
}
