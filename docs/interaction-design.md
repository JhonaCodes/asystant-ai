# Interacción

El asistente es una sección del producto. El botón abre una superficie que se puede cerrar para regresar al trabajo; la conversación permanece en la instancia. La pantalla completa es otra presentación del mismo widget.

- Encabezado: nombre configurable, icono del asistente, estado con icono + texto y cierre opcional.
- Conversación: mensajes seleccionables, burbuja discreta para el usuario y tarjetas de resultados.
- Pensamiento: icono de destellos e indicador animado. La ejecución de tools usa un icono distinto. Completado, detenido y error tienen su propio símbolo.
- Permiso: tarjeta con una descripción local de lo que se hará, “Continuar” y “Ahora no”. Sin modal adicional. Rechazar devuelve la decisión al modelo sin ejecutar.
- Selección: chips seleccionables y confirmación explícita; las opciones llegan a la tool.
- Compositor: una línea inicial que crece hasta cinco, etiqueta compacta del modelo y botón de envío en píldora. Durante la operación cambia a detener. Deshabilitado si no hay texto o no se completó init.
- Scroll: sigue el contenido nuevo cuando el usuario está cerca del final y muestra las decisiones pendientes; permite revisar mensajes anteriores.

Los colores siguen el tema del host. `AsystantTheme` agrupa medidas, radios, ancho máximo y tamaños. `AsystantStrings` agrupa etiquetas; se puede especializar sin editar el SDK. El campo no muestra el control de resize del prototipo HTML.

La app de ejemplo incluye bottom sheet, panel lateral y pantalla completa. Las pruebas adaptativas cubren 320×640, 390×844, 600×320, 1440×900, teclado móvil y escala de texto 1.5. Las capturas `asystant-*.png` corresponden a la app Flutter ejecutándose en web. Los prototipos `liria-preview*` son históricos.
