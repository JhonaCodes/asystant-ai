/// Botánica's assistant, built on the asystant_ai library.
///
/// Everything about the assistant lives here: its definition and system
/// prompts (`workspace/`), the tools the model may call (`tools/`) and the
/// connection to the model provider. The rest of the app imports this file
/// and uses one widget, [AiAssistantButton]; nothing else is public.
library;

import 'package:asystant_ai/asystant_ai.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logger_rs/logger_rs.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

import 'package:host_app/src/core/navigation/route_screen.dart';
import 'package:host_app/src/core/network/api_failure.dart';
import 'package:host_app/src/modules/assessment/model/goal.dart';
import 'package:host_app/src/modules/assessment/model/recommendation_snapshot.dart';
import 'package:host_app/src/modules/assessment/model/symptom.dart';
import 'package:host_app/src/modules/assessment/viewmodel/assessment_viewmodel.dart';
import 'package:host_app/src/modules/plant/model/plant.dart';
import 'package:host_app/src/modules/plant/model/preparation.dart';
import 'package:host_app/src/modules/plant/ui/widget/origin_badge.dart';
import 'package:host_app/src/modules/plant/ui/widget/plant_presentation.dart';
import 'package:host_app/src/modules/plant/viewmodel/plant_catalog_viewmodel.dart';
import 'package:host_app/src/modules/profile/model/biological_sex.dart';
import 'package:host_app/src/modules/profile/model/person_profile.dart';
import 'package:host_app/src/modules/profile/model/profile_entries.dart';
import 'package:host_app/src/modules/profile/ui/widget/profile_presentation.dart';
import 'package:host_app/src/modules/profile/viewmodel/profile_viewmodel.dart';
import 'package:host_app/src/modules/recommendation/ui/widget/recommendation_presentation.dart';
import 'package:host_app/src/modules/recommendation/ui/widget/recommendation_snapshot_content.dart';
import 'package:host_app/src/modules/recommendation/viewmodel/recommendation_viewmodel.dart';
import 'package:host_app/src/modules/reference/model/term_kind.dart';
import 'package:host_app/src/modules/reference/model/vocabulary_term.dart';
import 'package:host_app/src/modules/reference/viewmodel/reference_viewmodel.dart';
import 'package:host_app/src/shared/shared.dart';

part 'ai_service.dart';
part 'cards/plant_card_item.dart';
part 'cards/plant_list_card.dart';
part 'cards/recommendation_card.dart';
part 'tools/add_medication_tool.dart';
part 'tools/botanica_tools.dart';
part 'tools/list_plants_tool.dart';
part 'tools/recommend_plants_tool.dart';
part 'tools/save_profile_tool.dart';
part 'tools/tool_input.dart';
part 'tools/vocabulary.dart';
part 'ui/ai_assistant_button.dart';
part 'ui/botanica_card_content.dart';
part 'ui/plant_gallery.dart';
part 'ui/recommendation_digest.dart';
part 'workspace/ai_connection.dart';
part 'workspace/botanica_assistant.dart';
part 'workspace/botanica_prompts.dart';
part 'workspace/person_context.dart';
