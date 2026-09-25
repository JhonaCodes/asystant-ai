# Despliegue de asystant-ai

El componente que se despliega es `services/asystant_gateway`. Flutter incorpora los paquetes como dependencias; las tools siguen viviendo dentro de cada app.

## Requisitos

- PostgreSQL dedicado y persistente, con copias de seguridad. La cuenta de migración necesita permisos DDL; la cuenta de ejecución necesita acceso a las tablas creadas. El proceso de ejecución con `--serve` no aplica migraciones.
- Una clave válida del proveedor, guardada exclusivamente en el servidor.
- Un secreto aleatorio de al menos 32 bytes por producto, compartido solo entre su backend de login y el gateway.
- Un dominio HTTPS y un proxy que permita SSE sin buffering, con tiempo de espera superior a 120 segundos.
- Modelos, topes de precio y presupuesto definidos para cada producto/cliente. Los valores del ejemplo no representan tarifas actuales.

## Imagen y migraciones

Desde la raíz del repositorio:

```sh
docker build -t asystant-gateway:local services/asystant_gateway
cp services/asystant_gateway/.env.example services/asystant_gateway/.env
```

Completa ese archivo en el servidor. No se incluye en Git ni en el contexto de construcción. `DATABASE_URL` debe usar una dirección alcanzable desde el contenedor: `127.0.0.1` dentro de Docker identifica el propio contenedor. Para una base remota configura TLS conforme a tu proveedor.

Para una instalación de un servidor, con PostgreSQL externo:

```sh
docker compose -f services/asystant_gateway/compose.yaml up -d --build
curl --fail http://127.0.0.1:8787/health/ready
```

Compose ejecuta primero las migraciones y luego la API. Solo publica el puerto en loopback para conectar el proxy HTTPS del servidor. No elimina ni crea una base de datos. Los archivos `.env` de Compose respetan las comillas del JSON del ejemplo; al utilizar `docker run --env-file`, genera un archivo sin esas comillas exteriores porque ese comando las conserva literalmente.

En una plataforma con varias réplicas: construye una imagen por revisión; ejecuta **un único job** de esa imagen con `--migrate-only` y `DATABASE_URL`; solo después actualiza las réplicas con `--serve`. Ese job no necesita las claves del proveedor. Usa un rol DDL exclusivo para el job si la plataforma lo permite. No inicies varios jobs de migración simultáneos.

`GET /health/live` comprueba el proceso. `GET /health/ready` verifica además una consulta al esquema PostgreSQL. No consumen inferencia ni prueban la clave del proveedor. No exponen datos de clientes. Configura el balanceador para admitir tráfico únicamente cuando readiness responda 200.

Antes de detener una instancia, retírala del balanceador y espera a que terminen las inferencias activas. El apagado forzado puede dejar reservas pendientes: el plazo de cierre HTTP por sí solo no garantiza finalizar todos los trabajos de contabilidad en segundo plano.

## Conectar una app

1. Su backend verifica la sesión existente y emite un ticket firmado según el contrato del [gateway](../services/asystant_gateway/README.md#contrato-de-autenticación). La identidad y el cliente se obtienen del login validado.
2. Flutter conecta ese endpoint a `SessionSource` y configura `GatewayTransport` con el dominio HTTPS del gateway.
3. La inicialización registra los esquemas de tools y prompts; el servidor responde con los modelos permitidos y el modelo asignado al cliente.
4. La app muestra el widget aprobado. El modelo propone llamadas; el SDK comprueba permisos, solicita confirmación cuando corresponde y ejecuta la implementación local.

## Verificación y operación

Antes de promover a producción, prueba login, renovación, revocación, una tool confirmada y otra cancelada, aislamiento entre clientes, límite de presupuesto y bloqueo del modelo no asignado. El test optativo `scripts/live_openrouter.py` prueba una inferencia real con una base aislada y presupuesto limitado; requiere una clave válida. La clave disponible durante el desarrollo respondió HTTP 401, por lo que esa verificación externa está pendiente.

Después de construir la imagen, `python3 scripts/check_container.py` comprueba el usuario sin privilegios, la ejecución con filesystem de solo lectura, el job de migración y los estados de salud antes de migrar y después de detener PostgreSQL. Usa contenedores y una red desechables, no publica puertos y elimina exclusivamente sus propios recursos. Requiere Docker y descarga `postgres:18-bookworm`; no llama a un proveedor de IA.

Los modelos y presupuestos se administran mediante configuración del servidor y requieren reinicio. Las reservas cuyo costo no pudo confirmarse permanecen pendientes: esta versión no incorpora conciliación automática ni panel administrativo. Revisa esos registros contra el proveedor antes de liberar fondos. Guarda copias de PostgreSQL; las cuotas no deben reiniciarse recreando la base.

Para volver a una versión anterior, conserva la imagen de la revisión previa y verifica su compatibilidad con el esquema actual. No ejecutes migraciones destructivas ni borres volúmenes para hacer rollback.

El destino y dominio están pendientes de definición. Estos archivos preparan el despliegue; no constituyen una publicación ya realizada.
