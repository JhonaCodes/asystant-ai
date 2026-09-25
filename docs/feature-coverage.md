# Funcionalidades de asystant-ai

| Pedido | Implementación en la librería / API |
| --- | --- |
| Integrar dentro de cualquier app | `AsystantAI` + `AsystantChat`, sin router ni login propios |
| Abrir desde un botón | `AsystantButton`, con bottom sheet; ejemplo de end drawer y fullscreen |
| Mobile, web y desktop | Widgets adaptables; pruebas en teléfono y escritorio; proyectos de ejemplo multiplataforma |
| Nombre del asistente configurable | `AsystantAI(name: ...)`; marca del paquete independiente |
| Registro simple de tools | `List<AsystantTool>`, `TypedAsystantTool<T>`, validación antes de init y ejecución local |
| Prompts por aplicación | `List<AsystantSystemPrompt>` |
| Inicialización después del login | `init` explícito con `SessionSource`; no depende de que haya transcurrido un frame |
| Estado reactive_notifier | Servicio por instancia y ViewModel sin parámetros de constructor |
| genUI precreado | Tarjetas de resumen, entidad, selección, permisos y resultado |
| Tools de fábrica opcionales | `PresentationTool`, activado/omitido con `builtInTools` |
| Permisos suaves | Tarjeta inline, continuar/ahora no, vinculada a argumentos y sesión |
| Pasos e iconos del demo | Desplegable de las acciones locales reales, con estados terminales |
| Pensamiento y detener | Indicadores animados, streaming incremental y cancelación; sin reintentar escrituras |
| Chat mejorable | Tema del host, `AsystantTheme`, textos reemplazables y widgets separados |
| Tarjetas en orden | `ChatState.entries` intercala resultados con sus mensajes |
| Autenticación agnóstica al producto | Ticket firmado por el backend del producto, intercambio por token temporal |
| Expiración y refresh | Renovación antes de inferir, identidad estable, revocación por login |
| Presupuesto por cliente | Límites tenant/usuario, overrides, reservas PostgreSQL y consumo persistido |
| Modelo por cliente | `client_models`, default por tenant/usuario, selector opcional; validación en cada petición |
| Consultar política efectiva | `GET /v1/models` autenticado y respuesta de init con modelo asignado |
| OpenRouter inicial | Adaptador + ID configurado `openai/gpt-oss-20b` en el ejemplo de servidor |
| Otros proveedores | OpenAI, Gemini, Claude y OpenCode Zen/Go con su protocolo configurado |

La demo HTML anterior es una referencia visual; los componentes y estados de esta tabla están en los paquetes Flutter y el gateway. La app de ejemplo consume esos mismos paquetes mediante dependencias locales.

Persistencia de conversaciones, archivos multimodales, consola administrativa y conciliación automática de reservas inciertas no se presentan como implementados. No son necesarios para invocar las tools locales, pero sí deben tratarse explícitamente si se incorporan después. Las pruebas externas de proveedores siguen limitadas por la credencial de OpenRouter rechazada con 401; las pruebas de integración locales no simulan que esa inferencia haya funcionado.
