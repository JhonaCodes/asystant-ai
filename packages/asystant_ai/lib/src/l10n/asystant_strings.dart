import 'package:flutter/material.dart';
import 'package:asystant_core/asystant_core.dart';

import '../model/chat_state.dart';
import '../model/assistant_step.dart';

/// Pass a subclass to AsystantChat to customize wording or add a language.
class AsystantStrings {
  const AsystantStrings({this.spanish = true});
  final bool spanish;
  static AsystantStrings of(BuildContext context) => AsystantStrings(
    spanish: Localizations.localeOf(context).languageCode == 'es',
  );
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
  String get you => spanish ? 'Tú' : 'You';

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
      spanish
          ? 'Ese tipo de archivo no se acepta. Permitidos: ${policy.normalizedExtensions.join(', ')}.'
          : 'That file type is not accepted. Allowed: ${policy.normalizedExtensions.join(', ')}.',
    AttachmentIssue.tooLarge =>
      spanish
          ? 'El archivo supera ${fileSize(policy.maxFileBytes)}.'
          : 'The file is larger than ${fileSize(policy.maxFileBytes)}.',
    AttachmentIssue.empty =>
      spanish ? 'El archivo está vacío.' : 'The file is empty.',
    AttachmentIssue.unreadable =>
      spanish ? 'No se pudo leer el archivo.' : 'The file could not be read.',
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
