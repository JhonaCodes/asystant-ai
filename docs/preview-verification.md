# Verificación de la propuesta visual

25 de septiembre de 2026. Prototipo HTML local renderizado con el wrapper de visualize y Chromium headless mediante Playwright.

- Sin errores JavaScript capturados.
- Flujos comprobados: aprobar y completar, detener antes de completar, rechazar sin resultado creado, ajustar selección y pluralización con una actividad.
- 96 combinaciones sin desbordamiento horizontal: anchos 320/390/736/1024, superficies fullscreen/drawer/sheet y estados selección/permiso/actividad/resultado/rechazo/inicio/sesión vencida/presupuesto agotado.
- Capturas de escritorio y móvil inspeccionadas; corrección posterior de la etiqueta singular.
- Movimiento reducido contemplado por CSS; la actividad animada es una simulación acotada.

Estas comprobaciones no validan accesibilidad exhaustiva, teclado nativo, Flutter, permisos de negocio, modelo real ni seguridad del gateway. No se ejecutaron pruebas en los proyectos AulaMás de referencia. No se emitieron credenciales ni se consumió inferencia.

## Revisión del campo de mensaje y estados

- Campo compacto de 62 px de altura inicial en la captura móvil; textarea crece hasta 168 px. Botón cápsula con texto o alternativa circular configurable, área interactiva de 48 px.
- Capturas de panel lateral y móvil revisadas en modo oscuro.
- 288 combinaciones comprobadas sin desbordamiento horizontal: 4 anchos × 3 superficies × 12 estados × temas claro/oscuro.
- Sin errores JavaScript ni iconos pendientes de renderizar.
- Enviar con clic y Enter, detener envío y ejecución, completar tras confirmar, conservar borrador offline y al renovar sesión, desactivar envío vacío/sin conexión, variante circular y movimiento reducido comprobados.
- Se corrigió el envío del prototipo para que su interacción local no dependa de la capacidad del iframe de enviar formularios.
