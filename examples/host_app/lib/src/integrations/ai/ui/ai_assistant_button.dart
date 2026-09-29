part of '../ai.dart';

/// Opens the assistant: a sheet on phones, a side panel on tablets.
class AiAssistantButton extends StatelessWidget {
  const AiAssistantButton({super.key});

  @override
  Widget build(BuildContext context) => AsystantButton(
    assistant: _AiService.assistant.notifier,
    strings: const AsystantStrings(spanish: true),
    cardContentBuilder: _BotanicaCardContent.of,
  );
}
