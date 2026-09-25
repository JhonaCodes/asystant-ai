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
  String get allow => spanish ? 'Continuar' : 'Continue';
  String get deny => spanish ? 'Ahora no' : 'Not now';
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
    _ =>
      spanish
          ? 'No pudimos completar la solicitud. Puedes intentarlo de nuevo; revisa antes si hubo cambios en la app.'
          : 'The request could not be completed. You can try again; first check for changes in the app.',
  };
}
