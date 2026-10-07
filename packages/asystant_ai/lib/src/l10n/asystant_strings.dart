import 'package:flutter/material.dart';
import 'package:asystant_core/asystant_core.dart';

import '../model/chat_state.dart';
import '../model/assistant_step.dart';
import '../model/asystant_action_policy.dart';

/// Pass a subclass to AsystantChat to customize every built-in label.
/// English is the default; a host explicitly selects or implements a locale.
class AsystantStrings {
  const AsystantStrings({this.spanish = false});
  final bool spanish;
  static const AsystantStrings english = AsystantStrings();
  static const AsystantStrings spanishLabels = AsystantStrings(spanish: true);

  /// Selects host-supplied strings for any language or region. Keys may be
  /// language tags (`fr`, `pt-BR`) or language codes (`pt`). A region-specific
  /// match wins; an unknown locale falls back to English. The built-in
  /// Spanish bundle is used only when the host did not register `es`.
  static AsystantStrings forLocale(
    Locale locale, {
    Map<String, AsystantStrings> translations = const {},
  }) {
    final tag = locale.toLanguageTag().toLowerCase();
    final language = locale.languageCode.toLowerCase();
    for (final entry in translations.entries) {
      if (entry.key.replaceAll('_', '-').toLowerCase() == tag) {
        return entry.value;
      }
    }
    for (final entry in translations.entries) {
      if (entry.key.toLowerCase() == language) {
        return entry.value;
      }
    }
    return language == 'es' ? spanishLabels : english;
  }

  /// Used when the host did not pass strings. Device locale is not assumed.
  static AsystantStrings of(BuildContext context) => english;
  String get steps =>
      spanish ? 'Pasos de esta solicitud' : 'Steps in this request';
  String stepPhase(StepPhase phase) => switch (phase) {
    StepPhase.preparing => spanish ? 'Preparando' : 'Preparing',
    StepPhase.permission =>
      spanish ? 'Esperando tu decisión' : 'Waiting for your decision',
    StepPhase.running => spanish ? 'Ejecutando' : 'Running',
    StepPhase.completed => spanish ? 'Completado' : 'Completed',
    StepPhase.declined => spanish ? 'No autorizado' : 'Declined',
    StepPhase.canceled => spanish ? 'Detenido' : 'Stopped',
    StepPhase.failed => spanish ? 'No se pudo completar' : 'Could not complete',
  };
  String get connect => spanish ? 'Conectar asistente' : 'Connect assistant';

  String get linkFailure => spanish
      ? 'No se pudo abrir el enlace. Puedes copiarlo e intentarlo de nuevo.'
      : 'Could not open this link. You can copy it and try again.';

  String get imageOmitted => spanish ? 'Imagen omitida' : 'Image omitted';

  String get send => spanish ? 'Enviar' : 'Send';
  String get stop => spanish ? 'Detener' : 'Stop';
  String get close => spanish ? 'Cerrar' : 'Close';
  String get allow => spanish ? 'Autorizar' : 'Authorize';
  String get deny => spanish ? 'Rechazar' : 'Decline';
  String get cancel => spanish ? 'Cancelar' : 'Cancel';
  String get privateInputHint => spanish
      ? 'Estos datos se entregan solo a la acción local y no se envían al asistente.'
      : 'These values go only to the local action and are not sent to the assistant.';
  String get showPrivateInput => spanish ? 'Mostrar valores' : 'Show values';
  String get hidePrivateInput => spanish ? 'Ocultar valores' : 'Hide values';
  String get you => spanish ? 'Tú' : 'You';

  // Provider settings. Override these getters in a host string bundle.
  String get aiSettings => spanish ? 'Configurar IA' : 'AI settings';
  String get providerSettingsTitle =>
      spanish ? 'Proveedor del chat' : 'Chat provider';
  String get providerSettingsDescription => spanish
      ? 'Elige cómo se conecta el chat principal. Las claves se guardan en este dispositivo.'
      : 'Choose how the main chat connects. Keys stay on this device.';
  String get providerLabel => spanish ? 'Proveedor' : 'Provider';
  String get providerAppAccount => spanish ? 'Cuenta de la app' : 'App account';
  String get providerOpenAi => 'OpenAI / GPT';
  String get providerOpenRouter => 'OpenRouter';
  String get providerGemini => 'Gemini';
  String get providerAnthropic => 'Claude API';
  String get providerCompatible =>
      spanish ? 'Otro compatible con OpenAI' : 'Other OpenAI-compatible';
  String get primaryModelOptional =>
      spanish ? 'Modelo principal (opcional)' : 'Primary model (optional)';
  String get primaryModelAllowedHint => spanish
      ? 'Debe estar permitido por tu cuenta.'
      : 'It must be allowed by your account.';
  String get primaryModel => spanish ? 'Modelo principal' : 'Primary model';
  String get automatic => spanish ? 'Automático' : 'Automatic';
  String get primaryModelId =>
      spanish ? 'ID del modelo principal' : 'Primary model ID';
  String get providerName => spanish ? 'Nombre del proveedor' : 'Provider name';
  String get providerBaseUrl => 'HTTPS API base URL';
  String get providerBaseUrlHint => 'https://api.example.com/v1/';
  String get providerApiKey => spanish ? 'Clave API' : 'API key';
  String get providerSavedKeyHint => spanish
      ? 'Clave guardada. Déjalo vacío para conservarla.'
      : 'Key saved. Leave blank to keep it.';
  String get providerClaudeApiHint => spanish
      ? 'Usa una clave de Claude API; el inicio de sesión de Claude Code no funciona en el móvil.'
      : 'Use a Claude API key; Claude Code sign-in is unavailable on mobile.';
  String get providerTestConnection =>
      spanish ? 'Probar conexión' : 'Test connection';
  String get providerSaving => spanish ? 'Guardando…' : 'Saving…';
  String get providerSaveAndUse => spanish ? 'Guardar y usar' : 'Save and use';
  String get providerDeleteLocalKey =>
      spanish ? 'Eliminar clave local' : 'Delete local key';
  String get providerSettingsUnavailable =>
      spanish ? 'Configuración no disponible.' : 'Settings are unavailable.';
  String get providerSecureStorageReadFailed => spanish
      ? 'No se pudo leer el almacén seguro.'
      : 'Could not read secure storage.';
  String get providerApplyFailed => spanish
      ? 'No se pudo aplicar la configuración.'
      : 'Could not apply the settings.';
  String get providerConnectionVerified =>
      spanish ? 'Conexión verificada.' : 'Connection verified.';
  String get providerVerificationRejected => spanish
      ? 'El proveedor rechazó la clave o no permite verificarla.'
      : 'The provider rejected the key or does not support verification.';
  String get providerCheckFailed => spanish
      ? 'No se pudo comprobar la conexión.'
      : 'Could not check the connection.';
  String get providerDeleteKeyFailed =>
      spanish ? 'No se pudo eliminar la clave.' : 'Could not remove the key.';
  String providerFormatError(String message) => switch (message) {
    'Enter a model ID.' => spanish ? 'Escribe el ID del modelo.' : message,
    'Enter an HTTPS API base URL.' =>
      spanish ? 'Escribe una URL HTTPS válida para la API.' : message,
    'Enter an API key.' => spanish ? 'Escribe una clave API.' : message,
    'This provider is not available in this app.' =>
      spanish ? 'Este proveedor no está disponible en esta app.' : message,
    _ => spanish ? 'Revisa los datos del proveedor.' : message,
  };

  String get secretReferenceExpired => spanish
      ? 'La referencia privada ya no está disponible. Envíala de nuevo.'
      : 'The private reference has expired. Send it again.';
  String get privateActionCompleted => spanish
      ? 'Acción completada con un valor privado'
      : 'Action completed with a private value';
  String get privateActionFailed => spanish
      ? 'La acción con valor privado falló.'
      : 'The action using a private value failed.';

  // Header and conversations.
  String get expand => spanish ? 'Ampliar chat' : 'Expand chat';
  String get collapse => spanish ? 'Reducir chat' : 'Shrink chat';
  String get history => spanish ? 'Ver conversaciones' : 'Conversations';
  String get conversations => spanish ? 'Conversaciones' : 'Conversations';
  String get newConversation =>
      spanish ? 'Nueva conversación' : 'New conversation';
  String get deleteConversation =>
      spanish ? 'Eliminar conversación' : 'Delete conversation';
  String get deleteTitle =>
      spanish ? '¿Eliminar esta conversación?' : 'Delete this conversation?';
  String get deleteBody => spanish
      ? 'Se elimina y no podrás volver a leerla. Lo que el asistente ya hizo en la app no se deshace.'
      : 'It is deleted and you will not be able to read it again. What the assistant already did in the app is not undone.';
  String get delete => spanish ? 'Eliminar' : 'Delete';
  String get moreActions => spanish ? 'Más opciones' : 'More options';
  String get back => spanish ? 'Volver al chat' : 'Back to the chat';
  String get current => spanish ? 'Actual' : 'Current';
  String get noConversations => spanish
      ? 'Todavía no tienes conversaciones. La que empieces queda aquí.'
      : 'No conversations yet. The one you start stays here.';
  String get untitledConversation =>
      spanish ? 'Conversación sin mensajes' : 'Conversation without messages';

  // Turn activity.
  String get activityCompleted =>
      spanish ? 'Actividad completada' : 'Activity completed';
  String get activityWithIssues => spanish
      ? 'Actividad finalizada con novedades'
      : 'Activity finished with issues';
  String get activityEvents =>
      spanish ? 'Lo que hizo el asistente' : 'What the assistant did';
  String get liveActivity => spanish ? 'Trabajando…' : 'Working…';
  String get requestReceived =>
      spanish ? 'Solicitud recibida' : 'Request received';
  String get analyzing =>
      spanish ? 'Analizando la solicitud' : 'Analyzing the request';
  String get drafting =>
      spanish ? 'Redactando la respuesta' : 'Writing the answer';
  String thinkingAs(String name) =>
      spanish ? '$name está pensando' : '$name is thinking';
  String writingAs(String name) =>
      spanish ? '$name está escribiendo' : '$name is writing';
  String usingToolAs(String name) =>
      spanish ? '$name está usando la app' : '$name is using the app';
  String get reviewBeforeAuthorizing =>
      spanish ? 'Revisa antes de autorizar' : 'Review before authorizing';
  String get chooseBeforeContinuing =>
      spanish ? 'Elige antes de continuar' : 'Choose before continuing';
  String get continueAction => spanish ? 'Continuar' : 'Continue';
  String get approvalRequired =>
      spanish ? 'Requiere aprobación' : 'Approval required';
  String get allowAllForSession =>
      spanish ? 'Aceptar todas en esta sesión' : 'Approve all for this session';
  String get allowAllForSessionDetail => spanish
      ? 'Autoriza esta acción y las siguientes que permitan aprobación de sesión, hasta que cierres sesión.'
      : 'Authorizes this and later actions that allow session approval, until you sign out.';
  String get awaitingDecision => spanish
      ? 'Hay una acción esperando tu respuesta: usa Autorizar o Rechazar.'
      : 'An action is waiting for you: use Authorize or Decline.';

  // Context window.
  String tokens(int count) {
    if (count < 1000) {
      return '$count';
    }
    final thousands = count / 1000;
    final text = thousands >= 100
        ? thousands.round().toString()
        : thousands.toStringAsFixed(1);
    return '${spanish ? text.replaceAll('.', ',') : text} k';
  }

  String contextPercent(int percent) =>
      spanish ? '$percent % usado' : '$percent % used';

  String contextCompactPercent(int percent) => '$percent%';

  String sensitivityLevel(AsystantSensitivityLevel level) => switch (level) {
    .none => spanish ? 'Nulo' : 'None',
    .low => spanish ? 'Bajo' : 'Low',
    .medium => spanish ? 'Medio' : 'Medium',
    .high => spanish ? 'Alto' : 'High',
    .admin => 'Admin',
  };
  String contextUsed(int used) => '${tokens(used)} tokens';
  String get contextTitle =>
      spanish ? 'Memoria de la conversación' : 'Conversation memory';
  String contextDetail(int percent, int used, int limit) => spanish
      ? 'Esta conversación ocupa el $percent % de lo que el asistente puede tener en cuenta a la vez (${tokens(used)} de ${tokens(limit)} tokens). Cuando se llene, empieza una nueva para que no pierda el hilo.'
      : 'This conversation uses $percent % of what the assistant can keep in mind at once (${tokens(used)} of ${tokens(limit)} tokens). When it fills up, start a new one so it keeps track.';
  String get understood => spanish ? 'Entendido' : 'Got it';
  String get contextWarningTitle => spanish
      ? 'Esta conversación está casi llena'
      : 'This conversation is almost full';
  String get contextWarningBody => spanish
      ? 'El asistente pronto no podrá tener en cuenta todo lo que se dijo. Empieza una nueva para que no pierda el hilo.'
      : 'The assistant will soon be unable to keep everything in mind. Start a new one so it keeps track.';
  String get startNewNow => spanish ? 'Empezar una nueva' : 'Start a new one';

  // Attachments.
  String get attach => spanish ? 'Adjuntar archivos' : 'Attach files';
  String get attachPrivateValue => spanish ? 'Adjuntar valor' : 'Attach value';
  String get privateValueTitle =>
      spanish ? 'Adjuntar valor privado' : 'Attach private value';
  String get privateValueDescription => spanish
      ? 'Pega o escribe el valor aquí. El asistente recibirá solo una referencia.'
      : 'Paste or type the value here. The assistant receives only a reference.';
  String get privateValueType => spanish ? 'Tipo de valor' : 'Value type';
  String get privateValueField => spanish ? 'Valor privado' : 'Private value';
  String get privateValueHint => spanish
      ? 'Quedará en este dispositivo durante la sesión y se usará solo en una acción autorizada.'
      : 'It stays on this device for the session and is used only in an authorized action.';
  String get showPrivateValue => spanish ? 'Mostrar valor' : 'Show value';
  String get hidePrivateValue => spanish ? 'Ocultar valor' : 'Hide value';
  String get privateApiKey => spanish ? 'Clave API' : 'API key';
  String get privateToken => 'Token';
  String get privateUrl => 'URL';
  String get privatePassword => spanish ? 'Contraseña' : 'Password';
  String get privateOther => spanish ? 'Otro valor' : 'Other value';
  String get privateCustomName =>
      spanish ? 'Nombre para el asistente' : 'Name for the assistant';
  String removeAttachment(String name) =>
      spanish ? 'Quitar $name' : 'Remove $name';
  String attachmentCount(int count, int max) =>
      spanish ? '$count de $max adjuntos' : '$count of $max files';
  String fileSize(int bytes) => switch (bytes) {
    < 1024 => '$bytes B',
    < 1024 * 1024 => '${(bytes / 1024).round()} KB',
    _ =>
      '${(bytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', spanish ? ',' : '.')} MB',
  };
  String attachmentIssue(
    AttachmentIssue issue,
    AsystantAttachmentPolicy policy,
  ) => switch (issue) {
    AttachmentIssue.disabled =>
      spanish
          ? 'Este chat no acepta archivos.'
          : 'This chat does not take files.',
    AttachmentIssue.tooMany =>
      spanish
          ? 'Puedes adjuntar hasta ${policy.maxFiles} archivos por mensaje.'
          : 'You can attach up to ${policy.maxFiles} files per message.',
    AttachmentIssue.type =>
      policy.normalizedExtensions.isEmpty
          ? (spanish
                ? 'Ese archivo no cumple las reglas de adjuntos.'
                : 'That file does not meet the attachment rules.')
          : (spanish
                ? 'Ese archivo no cumple las reglas. Formatos permitidos: ${policy.normalizedExtensions.join(', ')}.'
                : 'That file does not meet the rules. Allowed formats: ${policy.normalizedExtensions.join(', ')}.'),
    AttachmentIssue.tooLarge =>
      spanish
          ? 'El archivo supera ${fileSize(policy.maxFileBytes)}.'
          : 'The file is larger than ${fileSize(policy.maxFileBytes)}.',
    AttachmentIssue.empty =>
      spanish ? 'El archivo está vacío.' : 'The file is empty.',
    AttachmentIssue.unreadable =>
      spanish ? 'No se pudo leer el archivo.' : 'The file could not be read.',
    AttachmentIssue.sensitiveContent =>
      spanish
          ? 'El archivo parece contener claves. Quítalas antes de compartirlo con el asistente.'
          : 'The file appears to contain credentials. Remove them before sharing it with the assistant.',
    AttachmentIssue.blockedContent =>
      spanish
          ? 'El contenido del archivo no cumple las reglas de este chat.'
          : 'The file content does not meet this chat’s rules.',
  };

  /// Day, month and year; the widget adds the time in the device's format.
  String shortDate(DateTime date) {
    const es = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    const en = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = date.toLocal();
    final month = (spanish ? es : en)[local.month - 1];
    return spanish
        ? '${local.day} $month ${local.year}'
        : '$month ${local.day}, ${local.year}';
  }

  String get placeholder =>
      spanish ? '¿Qué te gustaría hacer?' : 'What would you like to do?';
  String get welcome =>
      spanish ? 'Trabajemos dentro de tu app' : 'Let’s work inside your app';
  String get introduction => spanish
      ? 'Pide ayuda, consulta información o prepara una acción. Tú decides antes de aplicar cambios.'
      : 'Ask for help, look up information or prepare an action. You decide before changes are applied.';
  String get confirmation => spanish
      ? 'Revisa esta acción antes de continuar'
      : 'Review this action before continuing';
  String get model => spanish ? 'Modelo' : 'Model';
  String get pendingSession => spanish
      ? 'Conecta tu sesión para comenzar'
      : 'Connect your session to begin';
  String phase(ChatPhase phase) => switch (phase) {
    ChatPhase.idle => pendingSession,
    ChatPhase.initializing => spanish ? 'Conectando' : 'Connecting',
    ChatPhase.ready => spanish ? 'Listo para ayudarte' : 'Ready to help',
    ChatPhase.thinking => spanish ? 'Pensando' : 'Thinking',
    ChatPhase.executing =>
      spanish ? 'Usando una herramienta de la app' : 'Using an app tool',
    ChatPhase.permission =>
      spanish ? 'Esperando tu decisión' : 'Waiting for your decision',
    ChatPhase.done => spanish ? 'Completado' : 'Completed',
    ChatPhase.canceled => spanish ? 'Detenido' : 'Stopped',
    ChatPhase.error => spanish ? 'Necesita atención' : 'Needs attention',
  };

  /// What the chat says when a turn or the connection fails. By default
  /// the wording of [failure] for its code; a subclass can add what the
  /// provider reported (`AssistantFailure.detail`), e.g. which program is
  /// missing.
  String failureMessage(AssistantFailure failure) => this.failure(failure.code);

  String failure(FailureCode code) => switch (code) {
    FailureCode.network =>
      spanish
          ? 'No hay conexión con el servicio. Puedes conservar el mensaje e intentarlo más tarde.'
          : 'Could not reach the service. Keep your message and try again later.',
    FailureCode.authentication =>
      spanish
          ? 'Tu sesión cambió o venció. Vuelve a conectar el asistente.'
          : 'Your session changed or expired. Reconnect the assistant.',
    FailureCode.budget =>
      spanish
          ? 'Se alcanzó el presupuesto configurado por tu organización.'
          : 'Your organization’s configured budget has been reached.',
    FailureCode.limit =>
      spanish
          ? 'Se alcanzó el límite de esta operación. Puedes iniciar una nueva solicitud.'
          : 'This operation reached its limit. You can start a new request.',
    FailureCode.contextFull =>
      spanish
          ? 'Esta conversación ya no cabe en la memoria del asistente. Empieza una nueva para seguir.'
          : 'This conversation no longer fits in the assistant’s memory. Start a new one to continue.',
    FailureCode.rateLimited =>
      spanish
          ? 'El servicio está recibiendo muchas solicitudes. Espera unos segundos y vuelve a intentarlo.'
          : 'The service is receiving many requests. Wait a few seconds and try again.',
    _ =>
      spanish
          ? 'No pudimos completar la solicitud. Puedes intentarlo de nuevo; revisa antes si hubo cambios en la app.'
          : 'The request could not be completed. You can try again; first check for changes in the app.',
  };
}
