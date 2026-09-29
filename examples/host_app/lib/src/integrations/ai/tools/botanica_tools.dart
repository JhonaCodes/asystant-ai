part of '../ai.dart';

/// The actions the model may ask the app for. Each tool calls the public
/// methods of the app's view models, never a repository or the database.
abstract final class _BotanicaTools {
  static const List<AsystantTool> all = [
    _ListPlantsTool(),
    _SaveProfileTool(),
    _AddMedicationTool(),
    _RecommendPlantsTool(),
  ];
}
