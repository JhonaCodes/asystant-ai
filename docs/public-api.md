# API pública de asystant-ai

## Fachada

`AsystantAI(name: 'Asistente')` se extiende en cada app. Implementa `tools`; opcionalmente `systemPrompts`. `init` recibe `AssistantTransport`, preferencias opcionales de modelos y `builtInTools`. Omitir `models` delega el catálogo y el modelo predeterminado a la API. El servidor siempre decide la asignación efectiva por cliente; no se confía en un ID enviado por Flutter. Expone `isInitialized`, `isAuthenticated` y `dispose`.

`AsystantButton` abre un bottom sheet adaptable. `AsystantChat` es una sección sin router ni Scaffold propio: cabe en drawer, panel, ruta o pantalla completa. `AsystantTheme` se configura mediante `ThemeData.extensions`; los colores se heredan del `ColorScheme`. `AsystantStrings` permite español/inglés y se puede extender para cambiar textos. El nombre del asistente se decide por instancia.

## Una tool local

```dart
class CreateDraftTool extends AsystantTool {
  const CreateDraftTool();

  @override
  ToolDefinition get definition => const ToolDefinition(
    name: 'create_draft',
    description: 'Crear un borrador en el espacio actual.',
    fields: [
      ToolField(name: 'title', description: 'Título', kind: ToolFieldKind.string),
    ],
  );

  // Las tools piden confirmación por defecto.
  @override
  Future<Result<AssistantCard, AssistantFailure>> preview(
    ToolArguments arguments,
  ) async => Ok(AssistantCard(
    title: 'Guardar borrador',
    body: arguments.string('title'),
    kind: AssistantCardKind.permission,
  ));

  @override
  Future<Result<ToolOutcome, AssistantFailure>> execute(
    ToolArguments arguments,
    ToolContext context,
  ) async {
    context.checkCanceled();
    // Invoca aquí el servicio de la app. Conserva su autorización de negocio.
    // Propaga context.idempotencyKey a las escrituras que puedan repetirse.
    return Ok(const ToolOutcome(modelContent: 'Resultado confirmado por la app'));
  }
}
```

El ejemplo real está en `examples/host_app/lib/create_draft_tool.dart`. Para un contrato de entrada propio, usa `TypedAsystantTool<T>` e implementa `decode`, `previewInput` y `executeInput`.

Esquemas iniciales: string, integer, number finito, boolean y lista de strings. Campos obligatorios/opcionales; argumentos adicionales, tipos erróneos, nombres desconocidos y registros duplicados se rechazan. JSON solo vive en los codecs de los límites. Se pueden añadir tipos compuestos ampliando esos codecs sin cambiar los widgets.

`isAvailable` revalida disponibilidad antes de ejecutar. `requiresConfirmation` vale true por defecto. Solo las herramientas de lectura o presentación que lo permitan deben devolver false. `requiresSelection` requiere elegir al menos una opción de la tarjeta antes de continuar. Una selección devuelve valores de `options` mediante `ToolContext.selectedOptions`.

`ToolContext` expone cancelación e idempotencia. Cancelar no revierte una escritura que el servicio de la app ya haya confirmado. Para trabajo asíncrono, comprueba la cancelación de nuevo inmediatamente antes de escribir. El SDK nunca reintenta automáticamente una tool fallida o interrumpida.

## genUI

`AssistantCard` ofrece `summary`, `entity`, `selection`, `permission` y `result`. `GenUiCard` es público. Las vistas previas de permisos vienen de la implementación local de la tool; el texto del modelo no concede autorización.

`PresentationTool(kind: ...)` es opcional. Se activa incluyendo la instancia en `builtInTools`; se desactiva omitiéndola. Las tools de la app y las de fábrica comparten el registro y la validación. No se permite sobrescribir silenciosamente nombres repetidos.

## Sesión y transporte

Implementa `SessionSource`, o usa `CallbackSessionSource` con los callbacks de la autenticación actual:

- `identity`: identificador estable que incluya producto/tenant/usuario/sesión. Null sin login.
- `changes`: evento cuando cambie la identidad o se cierre sesión.
- `issueTicket`: llama al backend autenticado del producto para obtener un ticket corto firmado. Nunca firma desde Flutter.

`GatewayTransport` mantiene la credencial temporal solo en memoria. Antes de una inferencia, si está cerca de vencer, solicita un nuevo ticket y renueva el acceso; conserva el registro de tools. Un 401 descarta el token para la siguiente solicitud, sin repetir automáticamente la inferencia.

Antes de cerrar sesión, el host puede esperar `gateway.revokeSession()` para revocar todas las credenciales emitidas para ese login. Debe manejar el Result si no hay conexión. El token también vence por TTL y está limitado por la expiración de la sesión firmada. Cambiar la identidad en Flutter no sustituye la revocación del servidor.

La inicialización debe esperar la autenticación y dependencias, independientemente de que se invoque en un post-frame. No hace falta BuildContext para inicializar. Una llamada a `init` durante una operación activa no reconfigura el asistente.

## Progreso y orden de la conversación

`ChatState.steps` contiene las etapas reales de las tools de la solicitud actual: preparación, permiso, ejecución, completado, rechazo, cancelación o error. La librería presenta un desplegable de pasos con iconos; no genera razonamiento interno ficticio. `ChatState.entries` conserva el orden visible entre mensajes y tarjetas de resultados.

Errores de red, sesión y presupuesto tienen avisos e iconos diferenciados. Si falla la conexión antes de recibir una respuesta, se restaura el borrador cuando el usuario no ha escrito otro. No se reenvían mensajes ni se ejecutan tools automáticamente al reconectar.
