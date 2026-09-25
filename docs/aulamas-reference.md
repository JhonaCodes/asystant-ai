# AulaMás: evidencia y extracción

Revisión estática, 25 de septiembre de 2026. Repositorios de referencia en modo lectura, sin cambios, despliegues, consultas a cuentas ni ejecución de tests. Autorización explícita del usuario durante esta conversación.

## Rutas revisadas

- `/Volumes/Data/Private/Projects/JhonacodeProjects/AulamasProject/Platform/Desktop/operations-panel`
- `/Volumes/Data/Private/Projects/JhonacodeProjects/AulamasProject/Platform/Server/backend-api`
- `/Volumes/Data/Private/Projects/JhonacodeProjects/AulamasProject/Platform/Mobile/asystant_ia`: existe, pero está vacío, incluso incluyendo archivos ocultos.

## Cómo funciona hoy la emisión

1. `AiCredentialHttp` registra `POST /ai/credentials` dentro del scope school; la documentación identifica `/v1/school/ai/credentials`. Requiere `require_school_actor`, convierte a `AulaAiActor` y añade `Cache-Control: no-store`/`Pragma: no-cache`, también a errores del recurso.
2. El cuerpo solo contiene `bucket`; identidad y dinero no son autoridad del request.
3. `AiCredentialService.issue` obtiene institución/docente del actor, resuelve la asignación en DB y verifica correspondencia antes de provisionar.
4. `resolve_managed_allocation` valida permisos y políticas de institución y docente. Calcula cupo disponible, usa cuentas en microunidades USD y recupera la asignación vigente cuando corresponde. La asignación nueva vence al final del día UTC.
5. `AiManagedKeyService` reserva y reclama una emisión. Una asignación `issued` recupera el secreto sellado; no vuelve a crear una key por cada consulta. Una asignación `reserved` pasa a emisión con timeout; éxito requiere validar respuesta, sellar y persistir.
6. Fallos inciertos mantienen evidencia/reservas y no habilitan otro POST a ciegas. Hay servicios de consumo, revocación y recuperación administrativa.
7. La respuesta contiene `institution_id`, `staff_id`, `bucket`, `expires_at`, `refresh_after`, `allowed_models` y `api_key`. `refresh_after` es mínimo entre un minuto después de la consulta y la caducidad. No significa que la clave dure un minuto ni que se emita en el login mismo.

En el código inspeccionado, `allowed_models` contiene `openai/gpt-oss-120b`, no el 20b solicitado para esta librería. La documentación dice expresamente que esa lista restringe al cliente Aula-AI y no es un guardrail aplicado a la key de OpenRouter.

No se verificó el temporizador/refresh del cliente: la carpeta facilitada está vacía. Tampoco se demostró que logout revoque inmediatamente una key ya entregada. No se deduce ese comportamiento solo de que el endpoint valide la sesión al emitir.

## Archivos de evidencia

Relativos a backend-api:

- `src/handler/school/aula_ai_credential_handler.rs`
- `src/handler/school/session_guard.rs`
- `src/modules/aula_ai/service/aula_ai_credential_service.rs`
- `src/modules/aula_ai/service/aula_ai_managed_key_service.rs`
- `src/modules/aula_ai/repository/aula_ai_managed_policy_repository.rs`
- `src/modules/aula_ai/repository/aula_ai_managed_ledger_repository.rs`
- `src/modules/aula_ai/model/aula_ai_credential_model.rs`
- `src/modules/aula_ai/model/aula_ai_managed_key_model.rs`
- `src/modules/aula_ai/model/aula_ai_managed_ledger_model.rs`
- `src/modules/aula_ai/integration/aula_ai_managed_key_vault.rs`
- `docs/aula-ai-credential-recovery.md`

Relativos a operations-panel:

- `lib/src/modules/aula_ai/model/ai_credential_assignment.dart`
- `lib/src/modules/aula_ai/repository/ai_budget_repository.dart`
- `lib/src/modules/aula_ai/repository/ai_plan_repository.dart`
- `test/snapshots/v2_5_aula_ai_global.png` (inspeccionado visualmente)

Se localizaron suites de pruebas de credenciales, ledger, presupuesto, emisión, recuperación y revocación. No se ejecutaron y no se afirma que pasen.

## Qué conservar y qué desacoplar

| Concepto actual | Destino agnóstico |
|---|---|
| institución | tenant dentro de un productId |
| docente/staff | principal/subject autenticado |
| School actor/session guard | adaptador de emisor de confianza |
| políticas institución/docente | políticas tenant/usuario con scope de producto |
| daily/migration | bolsas configurables: recurrente o acumulada |
| microunidades, reservas, gasto y estados inciertos | conservar invariantes, adaptar schema e identidades |
| OpenRouter management y bóveda | adaptador de proveedor opcional, secreto siempre en servidor para gateway |
| revocación y conciliación | workers del servicio común |
| clases, usuarios escolares y permisos académicos | adaptador de AulaMás y tools del producto |

No copiar todo el módulo aula_ai: contiene otras funciones académicas y rutas de tools. Primero aislar el núcleo de identidad/consumo, con puertos de repositorio/proveedor y tests de invariantes; después integrar AulaMás como un consumidor más.

La ruta de migración no presupone que todos los proveedores emitan claves hijas. Se conserva el conocimiento de ledger, incertidumbre y revocación, y se introduce inferencia a través del gateway para aplicar modelos y políticas de forma centralizada.

## Validación antes de reemplazar el flujo actual

Probar con identidades de prueba que el adaptador produce el mismo tenant/usuario, que consultar credenciales no reserva dos veces, que nuevas credenciales no reinician cupo y que consumo tardío no libera dinero indebidamente. Comparar estados y redacción de errores sin registrar secretos. Migración de datos y compatibilidad de versiones requieren un plan separado; no se han tocado las bases ni claves existentes.
