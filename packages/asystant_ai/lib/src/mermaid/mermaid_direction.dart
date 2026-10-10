/// Where a flowchart starts and which way its steps advance.
///
/// Mermaid writes it after the keyword: `TB`/`TD` top to bottom, `BT`
/// bottom to top, `LR` left to right and `RL` right to left.
enum MermaidDirection {
  topDown,
  bottomUp,
  leftRight,
  rightLeft;

  /// Steps advance along the vertical axis.
  bool get isVertical => this == topDown || this == bottomUp;

  /// Steps advance against the axis: upwards or leftwards.
  bool get isReversed => this == bottomUp || this == rightLeft;

  /// The direction for a Mermaid keyword such as `TD`, or null.
  static MermaidDirection? fromKeyword(String keyword) =>
      switch (keyword.toUpperCase()) {
        'TB' || 'TD' => topDown,
        'BT' => bottomUp,
        'LR' => leftRight,
        'RL' => rightLeft,
        _ => null,
      };
}
