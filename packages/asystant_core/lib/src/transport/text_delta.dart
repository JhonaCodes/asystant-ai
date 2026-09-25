import 'inference_event.dart';

/// An incremental piece of assistant text received over SSE.
class TextDelta extends InferenceEvent {
  const TextDelta(this.text);
  final String text;
  TextDelta copyWith({String? text}) => TextDelta(text ?? this.text);
  @override
  bool operator ==(Object other) => other is TextDelta && text == other.text;
  @override
  int get hashCode => text.hashCode;
}
