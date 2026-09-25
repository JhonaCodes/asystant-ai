# Verificación de implementación · 25 de septiembre de 2026

## Context status

**Conforme.** Nombre final elegido: asystant-ai. SDK embebido en la app, lanzamiento desde botón, móvil/web/escritorio y nombre visible configurable. Referencias de AulaMás revisadas previamente en lectura; la carpeta de su posible SDK estaba vacía. No se modificaron repositorios de referencia. La API pública, ejemplos y documentos corresponden al código actual.

## Business-rule status

**Conforme para integración inicial.** Las tools viven en Flutter. Las escrituras piden aprobación por defecto. Rechazo, cancelación y cambio de sesión impiden ejecutar una aprobación pendiente. El host debe conservar sus permisos de negocio y verificar cancelación antes de confirmar efectos asíncronos. Los identificadores de idempotencia se entregan a las tools.

El gateway valida issuer/audience/algoritmo/tiempos y uso único del ticket. La credencial es temporal y su hash es lo único persistido. Revocación por login. Modelos y montos se configuran en servidor. Los límites diarios sobreviven a renovación, nuevos logins y nuevas conexiones al pool; las reservas simultáneas se serializan transaccionalmente.

## Code-quality findings

Hallazgos corregidos durante verificación: resultados incompletos tras cancelar una tool, parseo no tipado de respuestas de credenciales malformadas, estado de envío antes del repaint, permisos fuera de vista en ventanas pequeñas, cierre de selección sin opciones y orden de bloqueo de reservas/liquidación. Los widgets públicos están separados; las capas no ejecutan efectos del producto en servidor.

Las entradas/salidas JSON están en codecs y transporte. reactive_notifier administra el estado; los ViewModels se configuran mediante métodos y no por inyección en constructor. Los errores de proveedores no se propagan con secretos. Lint Flutter y Clippy sin hallazgos al cierre.

## Test verification

- 7 pruebas Dart: registro, argumentos, renovación conservando registro, respuesta de credencial malformada y stream truncado.
- 13 pruebas Flutter: aprobación única, rechazo, cambio de sesión, cancelación, independencia de instancias, integración de la tool en la app y layouts 320×640 / 390×844 / 600×320 / 1440×900, teclado y texto ampliado.
- 8 pruebas Rust: contratos de costo/tickets/transcript/registro, carrera de ocho reservas contra un mismo saldo, persistencia y renovación/revocación, endpoints HTTP completos con un proveedor de prueba.
- Prueba real adicional, opt-in: se intentó `openai/gpt-oss-20b` a través del SDK y gateway; OpenRouter rechazó la credencial del entorno (401). No se declara inferencia real aprobada. La reserva incierta permanece retenida en la base aislada de prueba.
- `flutter analyze`: sin incidencias.
- `cargo clippy --all-targets -- -D warnings`: aprobado.
- Builds: web release, Android debug, iOS Simulator debug y macOS debug completados. Windows/Linux incluyen proyectos de ejemplo, pero no se compilaron en este host macOS.
- Navegador real automatizado: apertura desde botón, entrada de texto, permiso, confirmación y resultado a 1280 px y 390 px. Capturas Flutter `asystant-desktop.png`, `asystant-permission.png`, `asystant-result.png`, `asystant-mobile.png`.

Las pruebas PostgreSQL usaron exclusivamente una base nueva de este proyecto, en el puerto 55439. No se usaron bases de las apps del usuario. Las correcciones relevantes se verificaron con fallos por aserción antes de su solución; no se consideran los errores de compilación como evidencia de comportamiento.

## Confidence report

Arquitectura y permisos locales: alta para el alcance probado. Presupuestos, sesión y transacciones: alta en las pruebas aisladas. Compatibilidad visual: verificada en los tamaños enumerados. Proveedores: adaptación implementada, con confianza limitada hasta completar sus pruebas externas; Messages/Responses entregan respuesta completa, Chat Completions tiene streaming.

## Go / No-Go

**GO para integrar y evaluar el SDK en una app de desarrollo.** **NO-GO para publicar como servicio de producción validado:** falta completar la prueba externa con una credencial válida y conectar un emisor de tickets al login real de cada producto. No se ha desplegado ni publicado ningún paquete.

## Residual risks

- La reserva de costos inciertos no se libera sola. Falta automatizar conciliación con los proveedores y administración/retención del ledger.
- Las tarifas de proveedores directos se configuran en servidor; deben reflejar su límite máximo vigente. El costo observado que supere una reserva se registra, pero no puede deshacer consumo ya facturado.
- El SDK es inicialmente de texto y tools con campos escalares/listas de strings. Adjuntos multimodales, persistencia de conversaciones y esquemas anidados no están incluidos en esta versión.
- Los efectos ya confirmados por una tool no se revierten al cancelar. Cada app debe aplicar autorización e idempotencia en su repositorio.
- OpenCode Go limita los casos de uso admitidos; la configuración de un modelo debe respetar su endpoint y disponibilidad real.


## Ampliación: fidelidad del demo y modelo por cliente

Contexto: se trasladaron a la librería los pasos desplegables reales y el orden intercalado de tarjetas/mensajes; el estado de red conserva el borrador sin reenvío automático. Los avisos de conexión, credencial y presupuesto tienen iconos propios. La guía `feature-coverage.md` recoge el alcance acordado.

Regla de negocio: el modelo se resuelve por producto, tenant y opcionalmente usuario. `GET /v1/models` y `init` devuelven la política efectiva. El modelo asignado prevalece sobre preferencias antiguas de la app; `allow_selection: false` bloquea tanto el selector como una petición HTTP manipulada. Las reglas se revalidan al inferir y no se elige el tenant desde datos del frontend.

Pruebas nuevas: RED observado al registrar todos los modelos en vez del asignado, al rechazar en el SDK un modelo asignado distinto del solicitado y al no registrar los pasos. GREEN después de implementar las reglas. Se añadieron cobertura de precedencia por tenant/usuario, rechazo de modelo ajeno, bloqueo del selector, selección explícita, orden de resultados y borrador de red. Total: 28 pruebas locales aprobadas; smoke externo opt-in omitido.

Calidad: widgets separados para encabezado, conversación, mensajes, pasos y errores. Eliminados los `part` de eventos; importaciones ordinarias y fallo tipado para eventos desconocidos. `flutter analyze` y Clippy se verifican junto con los tests. Build web actualizado; las compilaciones nativas documentadas arriba corresponden al cierre anterior y no se repitieron para estos cambios de Dart.

GO para integrar esta ampliación. Se mantienen las limitaciones externas y operativas ya enumeradas. Las políticas de modelos se administran en configuración y requieren reinicio del gateway; no se añadió un endpoint administrativo público. Tras retirar un modelo, una sesión antigua debe reinicializar su registro.

## Preparación del despliegue — 25 de septiembre de 2026

Se añadieron Dockerfile multietapa con usuario 10001, contexto restringido que excluye secretos, Compose con PostgreSQL externo, migración independiente `--migrate-only` y ejecución sin DDL con `--serve`. Se conserva el arranque sin argumentos con migraciones para desarrollo. Las rutas `/health/live` y `/health/ready` distinguen proceso vivo de base/esquema accesible.

Validación: imagen Linux ARM64 construida con `cargo build --release --locked`; existencia del tag Rust confirmada contra Docker Registry. Compose validado; `cargo fmt --check`, Clippy con `-D warnings` y ocho tests Rust aprobados. El test HTTP comprueba ambas rutas de salud. `scripts/check_container.py` pasó con PostgreSQL 18 desechable: readiness 503 sin esquema, 200 después de migrar y 503 al detener la base; liveness permaneció en 200. El proceso se ejecutó sin root y con filesystem de solo lectura. La base local de pruebas fue detenida y los recursos desechables del test fueron eliminados.

No se ha desplegado externamente; falta definir el destino. El repositorio y el PR se preparan como entrega separada de la publicación del servicio. La imagen se verificó en ARM64; para un servidor AMD64 debe construirse en esa arquitectura. Continúan pendientes la credencial válida de OpenRouter, la conexión del backend de cada producto para emitir tickets y la conciliación operativa de reservas inciertas. El procedimiento completo está en `docs/deployment.md`.
