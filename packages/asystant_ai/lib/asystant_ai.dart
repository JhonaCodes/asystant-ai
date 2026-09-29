/// Embeddable Flutter chat and local tools over any AsystantProvider
/// (OpenRouter, Claude Code, ...). Re-exports asystant_core, so every
/// provider the core package ships is available from this import.
library;

export 'package:asystant_core/asystant_core.dart';

export 'src/asystant_ai.dart';
export 'src/model/chat_state.dart';
export 'src/viewmodel/chat_view_model.dart';
export 'src/theme/asystant_theme.dart';
export 'src/l10n/asystant_strings.dart';
export 'src/widgets/asystant_chat.dart';
export 'src/widgets/asystant_button.dart';
export 'src/widgets/asystant_panel.dart';
export 'src/widgets/asystant_phone_sheet.dart';
export 'src/theme/asystant_device_type.dart';
export 'src/widgets/gen_ui_card.dart';
export 'src/model/assistant_step.dart';
export 'src/model/asystant_model_option.dart';
export 'src/model/asystant_turn_limits.dart';
export 'src/model/chat_entry.dart';
export 'src/model/conversation_snapshot.dart';
export 'src/service/asystant_conversation_store.dart';
export 'src/service/asystant_file_picker.dart';
export 'src/theme/asystant_metrics.dart';

export 'src/widgets/gen_ui_chart.dart';

export 'src/service/asystant_link_opener.dart';

export 'src/widgets/asystant_card_content.dart';
