# asystant-ai gateway

API independiente del producto. Rust/Actix + PostgreSQL/Diesel; el servidor **no ejecuta las tools de la app**.

## Arranque

Configura las variables de `.env.example` en el proceso y una base PostgreSQL dedicada. El binario lee variables de entorno; no carga archivos `.env` automáticamente. No copies valores de ejemplo a producción.

```sh
cargo run --manifest-path services/asystant_gateway/Cargo.toml --bin asystant_gateway
```

Sin argumentos se aplican las migraciones al arrancar, útil para desarrollo. En despliegues, ejecuta una vez `asystant_gateway --migrate-only` antes de iniciar las réplicas con `asystant_gateway --serve`. El listener predeterminado es `127.0.0.1:8787`; utiliza HTTPS en el punto de entrada de tu infraestructura. CORS permite exclusivamente `ASYSTANT_ORIGINS`.

El [procedimiento de despliegue](../../docs/deployment.md) incluye Docker, Compose con PostgreSQL externo, comprobaciones de salud y configuración de cada producto.

## Contrato de autenticación

El backend de cada producto registra su `issuer` y un secreto exclusivo de al menos 32 bytes. Tras verificar su login actual, emite un JWT **HS256** con:

```json
{
  "iss": "my-product",
  "aud": "asystant-gateway",
  "sub": "user-id",
  "tenant": "customer-id",
  "sid": "stable-login-id",
  "jti": "unique-ticket-id",
  "iat": 1790000000,
  "exp": 1790000060,
  "session_exp": 1790003600
}
```

Las fechas son segundos Unix; los valores anteriores ilustran la estructura. El ticket dura como máximo 120 segundos y es de un solo uso. `session_exp` es el vencimiento real de la sesión autenticada. El producto nunca acepta tenant/sub/sid arbitrarios del frontend ni comparte el secreto con Flutter.

1. `POST /v1/sessions/exchange` con `{ "ticket": "..." }` devuelve `{token, expires_at}` y `Cache-Control: no-store`.
2. El token opaco dura hasta 10 minutos, limitado además por `session_exp`. Solo se almacena su hash SHA-256.
3. El SDK reobtiene un ticket del backend antes de que venza la credencial y lo intercambia. Las credenciales pertenecen a la misma identidad estable; renovar no reinicia presupuesto.
4. `POST /v1/sessions/revoke` con Bearer revoca todas las credenciales del mismo login `sid`, incluyendo intercambios posteriores. Un nuevo login necesita un `sid` nuevo.

El contrato `SessionSource` reutiliza la autenticación del producto. Este repositorio no modifica los backends de tus apps para emitir tickets: incluye el contrato y pruebas de emisión/verificación, de modo que cada producto conecte su login existente.

## Inicialización y conversación

`POST /v1/assistants/init` con Bearer:

```json
{
  "tools": [{"name":"create_draft","description":"Create draft","parameters":{"type":"object","properties":{"title":{"type":"string"}},"required":["title"],"additionalProperties":false}}],
  "prompts": ["Help inside this app."],
  "models": ["openai/gpt-oss-20b"]
}
```

Devuelve `{id, models, default_model, allow_selection}`. El registro pertenece a la identidad completa y vence a las 24 horas; el host puede volver a inicializar tras ese plazo. El servidor elige el modelo predeterminado según producto → tenant → usuario. Siempre lo incluye aunque la app hubiera solicitado otro; los modelos adicionales solicitados deben estar permitidos por esa política. `models: []` delega todo el catálogo al servidor.

`POST /v1/turns` recibe `{registration_id, request_id, model, messages}`. Mensajes: `{role,content,calls,call_id}`; llamadas: `{id,name,arguments}`. Solo admite roles user/assistant/tool; exige una respuesta por llamada antes de continuar. Emite SSE con `text_delta`, `completed` o `failed`. El SDK ejecuta las llamadas confirmadas localmente y envía el resultado en la siguiente ronda.

`request_id` debe ser único por inferencia. Repetirlo devuelve 409; no reejecuta inferencia. La API no conserva una respuesta para replay. El SDK limita cada turno a ocho rondas y dieciséis llamadas por respuesta.

## Selección de modelo por cliente

Configura `default_model` y `client_models` dentro de cada entrada de `ASYSTANT_PRODUCTS`:

```json
{
  "models": ["fast", "advanced"],
  "default_model": "fast",
  "client_models": [
    {"tenant":"school-a","models":["fast"],"default_model":"fast","allow_selection":false},
    {"tenant":"school-b","models":["fast","advanced"],"default_model":"advanced","allow_selection":true},
    {"tenant":"school-b","subject":"limited-user","models":["fast"],"default_model":"fast","allow_selection":false}
  ]
}
```

`fast` y `advanced` son ejemplos de IDs previamente definidos en `ASYSTANT_MODELS`; cada uno puede apuntar a un proveedor/modelo diferente. Las demás propiedades del producto (issuer, secreto, presupuestos) siguen siendo obligatorias.

`GET /v1/models` con Bearer devuelve la política efectiva del usuario autenticado: `{models, default_model, allow_selection}`. No acepta un tenant suministrado por el frontend. Una regla de usuario prevalece sobre la de tenant; sin regla específica se aplica la del producto.

Con `allow_selection: false`, solo se expone y admite el modelo asignado. Con true, el selector de Flutter permite alternar entre los modelos admitidos. Cada inferencia vuelve a comprobar la política, además del registro: cambiar el payload no permite saltarse la asignación. Las asignaciones se administran en la configuración del servidor; esta versión no expone una ruta de administración pública para alterarlas.

Los cambios de configuración requieren reiniciar el gateway. Si retiras el modelo de una sesión ya abierta, sus inferencias se rechazan hasta volver a inicializar el asistente con la política actual. La renovación normal de credenciales mantiene el registro vigente.

## Presupuestos

Montos enteros en **USD micros**: 1 USD = 1,000,000. Política por producto con `daily_tenant_micros`, `daily_user_micros` y `budget_overrides` por tenant y opcionalmente usuario. Cambios de configuración se aplican al reiniciar; los consumos permanecen en PostgreSQL.

La reserva conservadora usa los topes de tokens y precios configurados. Se bloquean y actualizan las cuentas del tenant y usuario dentro de una transacción. El día es UTC. Rotar tokens, reiniciar procesos o cambiar de login no reinicia la cuenta diaria. Un override de cero bloquea nuevas solicitudes de ese cliente.

OpenRouter transmite el costo de uso cuando está disponible y recibe los techos de precio configurados. Otros proveedores se contabilizan con las tarifas configuradas, sin descontar caché; son estimaciones conservadoras y requieren mantener la política de precios al día. Un cargo observado mayor a la reserva se registra completo y bloquea gasto posterior cuando agota el saldo.

Ante timeout, stream incompleto o costo desconocido, la reserva queda `pending`: **no se libera automáticamente**. El trabajo de contabilidad continúa aunque el cliente se desconecte. Las reservas inciertas requieren conciliación operativa con el proveedor; esta versión aún no incluye worker automático ni panel de administración. La tabla `requests` permite identificar las pendientes y `GatewayRepository.settle` es idempotente por rechazo del segundo cierre. No debe liberarse una reserva solo por antigüedad.

## Proveedores

| `provider` | Adaptación implementada |
| --- | --- |
| `openrouter` | Chat Completions, streaming, tools, consumo y topes de precio |
| `openai` | Chat Completions o Responses según `wire_api` |
| `gemini` | Endpoint oficial compatible con OpenAI, streaming y tools |
| `anthropic` | Messages, tools y respuesta completa; todavía sin streaming incremental |
| `opencode_zen` | Chat Completions, Messages o Responses según `wire_api` |
| `opencode_go` | Chat Completions, Messages o Responses y cabecera de sesión propia; condicionado al uso admitido por el servicio |

`wire_api` admite `chat_completions` (por defecto), `messages` y `responses`. Debe corresponder al endpoint publicado para el modelo elegido. Messages y Responses devuelven una respuesta completa; el streaming incremental está implementado en Chat Completions. No todos los modelos de OpenCode usan el mismo protocolo. OpenCode Go está orientado a tráfico de agentes de programación; para asistentes de producto generales, verificar elegibilidad antes de habilitarlo. OpenRouter sigue siendo la configuración inicial.

Referencias oficiales: [OpenRouter](https://openrouter.ai/docs/api/api-reference/chat/send-chat-completion-request), [Gemini compatible con OpenAI](https://ai.google.dev/gemini-api/docs/openai), [OpenCode Zen](https://opencode.ai/docs/zen/), [OpenCode Go](https://opencode.ai/docs/go/). No se asume una sola convención universal.

## Verificación

```sh
cargo test --manifest-path services/asystant_gateway/Cargo.toml --test contracts
# Únicamente contra una base de pruebas dedicada:
ASYSTANT_TEST_DATABASE_URL=postgres://.../asystant_test cargo test --manifest-path services/asystant_gateway/Cargo.toml --test database --test http_api
cargo clippy --manifest-path services/asystant_gateway/Cargo.toml --all-targets -- -D warnings
```

Los tests HTTP utilizan un proveedor de prueba mediante el trait `InferenceProvider`, sin consumir claves o presupuesto externo. La prueba real con `openai/gpt-oss-20b` se intentó mediante el SDK y el gateway. La credencial disponible en el entorno fue rechazada por OpenRouter con HTTP 401; no se validó inferencia externa. Puede repetirse con `ASYSTANT_TEST_DATABASE_URL=... python3 scripts/live_openrouter.py` y una `OPENROUTER_API_KEY` válida. El script crea un emisor efímero, limita el presupuesto de prueba a USD 0.10 y no guarda ni imprime secretos.
