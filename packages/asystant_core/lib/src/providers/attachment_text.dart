/// How every provider cuts the text of an attached file, so both send the
/// same characters for the same file.
abstract final class AttachmentText {
  /// The first [limit] characters of [text], and whether anything was cut.
  static ({String text, bool truncated}) cut(
    String text, {
    required int limit,
  }) {
    final truncated = text.length > limit;
    return (
      text: truncated ? text.substring(0, limit) : text,
      truncated: truncated,
    );
  }
}
