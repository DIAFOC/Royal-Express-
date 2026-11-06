# Nombre

**Royal Express** (`royal-express`) — sistema de gestión logística para el centro de distribución LogistiXpress. Es la interfaz de operación del sistema: permite administrar datos maestros, recibir mercancía, preparar pedidos, planificar rutas, despachar unidades, registrar entregas y rastrear paquetes por guía.

El sistema corre como una aplicación local: FastAPI sirve la API y el panel desde el mismo proceso, y PostgreSQL conserva el estado operativo. El navegador se conecta únicamente a `127.0.0.1`.

> **Nota.** Este manual describe la versión 1.0 de Royal Express para LogistiXpress. Las cuentas, contraseñas y datos iniciales deben cambiarse antes de un despliegue en producción.

# Sinopsis (TL;DR)

## Si solo tienes cinco minutos

```bash
cd Royal
sudo docker compose down -v
sudo docker compose up --build
```

Abre `http://127.0.0.1:8000` y entra con una de las cuentas iniciales:

| Rol | Usuario | Contraseña | Para qué sirve |
|---|---|---|---|
| Administración | `admin` | `admin123` | Todo el sistema, usuarios y configuración |
| Operación | `operador` | `operador123` | Recepción, picking, rutas, entregas e inventario |
| Auditoría | `auditor` | `auditor123` | Lectura, bitácora, conteos y reportes |

## Flujo mínimo de operación

1. **Maestros → Pedidos → Nuevo pedido**: crea un pedido con dos líneas.
2. **Recepción → Nueva OC / cita**: programa una orden de compra.
3. **Recepción → Recibir**: captura cantidad, lote, caducidad, condición y ubicación.
4. **Picking / Packing → Generar ola**: surte las tareas, empaca, imprime etiquetas y aprueba QC.
5. **Rutas y reparto → Generar plan**: el pedido listo entra a una ruta.
6. **Rutas → Mapa y paradas → Despachar**: valida el escaneo de todos los bultos.
7. **Entrega**: registra firma, foto y nombre de quien recibió.
8. **Rastreo**: busca la guía y muestra la línea de tiempo.
9. **Inventario → Traslado interno**: mueve mercancía entre posiciones.
10. **Auditoría → Registrar conteo**: compara físico contra sistema.
11. **Reportes**: descarga PDF o Excel según tu rol.

> **Consejo.** La barra superior busca directamente por número de guía. Si conoces la guía, escribe `LX-00011` y presiona **Enter**.

\newpage

# Descripción

## Qué es este sistema

Royal Express es el sistema de gestión de almacén y reparto desarrollado para LogistiXpress. El panel está organizado alrededor del ciclo operativo del CEDIS:

- **Datos maestros:** clientes, productos, ubicaciones, lotes, proveedores y pedidos.
- **Entrada:** citas, órdenes de compra, recepción, lotes, caducidad e incidencias.
- **Preparación:** ola de picking, surtido guiado, empaque, etiquetas y control de calidad.
- **Salida:** consolidación de rutas, despacho, evidencia de entrega y entregas fallidas.
- **Trazabilidad:** rastreo por guía, bitácora, conteos cíclicos y reportes.

## Qué incluye y qué no

| Capacidad | Estado en esta versión |
|---|---|
| CRUD de maestros y pedidos | Incluido |
| Recepción con OC, lote, caducidad e incidencias | Incluido |
| Picking por pasillo y validación de SKU/ubicación | Incluido |
| Empaque, guías, etiquetas y QC | Incluido |
| Rutas consolidadas por zona/tipo/capacidad | Incluido |
| Despacho con validación de escaneo | Incluido |
| Entrega con firma, foto y fallas | Incluido |
| Rastreo por guía | Incluido |
| Inventario en vivo y traslados | Incluido |
| Conteos cíclicos y bitácora | Incluido |
| Reportes PDF/XLSX | Incluido |
| Lector físico de código de barras | No incluido: captura por teclado o simulación |
| PEPS/FIFO estricto por lote | Modelado con caducidad; no forzado en picking |
| Rechazo de QC con reempaque | No incluido en esta versión |
| PWA/offline y cámara móvil | No incluido |

# Roles y permisos

El sistema conserva tres roles base. Además, cada usuario tiene un **puesto** descriptivo que ayuda a organizar la operación, pero no cambia los permisos.

| Capacidad | Administración | Operación | Auditoría |
|---|---|---|---|
| Ver panel, rutas, rastreo | Sí | Sí | Sí |
| Crear/editar clientes, proveedores, lotes y pedidos | Sí | Sí | No |
| Crear/editar productos y ubicaciones | Sí | No | No |
| Crear OC y recibir mercancía | Sí | Sí | No |
| Generar ola, surtir, empacar, aprobar QC | Sí | Sí | No |
| Generar rutas, despachar y registrar entregas | Sí | Sí | No |
| Mover inventario y hacer traslados | Sí | Sí | No |
| Registrar conteos cíclicos | Sí | No | Sí |
| Ver bitácora y rotación | Sí | No | Sí |
| Gestionar usuarios y flota | Sí | No | No |
| Exportar reportes | Según tipo | Según tipo | Según tipo |

> **Advertencia.** La auditoría es de solo lectura para la operación diaria. Puede consultar y exportar, pero no puede generar rutas, surtir, empacar ni mover inventario. El backend también valida el rol: no es solo un botón oculto.

Los puestos disponibles son: Auxiliar de almacén, Montacarguista, Surtidor, Empacador, Chofer, Supervisor, Administración, Dirección y Auditoría.

# Acceso y puesta en marcha

## Opción A: Docker Compose

```bash
cd Royal
sudo docker compose up --build
```

Abre `http://127.0.0.1:8000`.

La primera vez, la imagen de PostgreSQL carga el esquema y la semilla. Si ya existía un volumen de una versión anterior, es obligatorio recrearlo porque el modelo cambió:

```bash
sudo docker compose down -v
sudo docker compose up --build
```

Para detener el sistema sin borrar datos:

```bash
sudo docker compose down
```

Para ver logs:

```bash
sudo docker compose logs -f db
sudo docker compose logs -f api
```

## Opción B: desarrollo local

```bash
cd Royal/royal-back
./scripts/setup_project.sh
./scripts/db.sh setup
./scripts/run_api.sh
```

El script `db.sh` usa Podman por defecto. Si usas Docker:

```bash
PODMAN=docker ./scripts/db.sh setup
```

## Credenciales iniciales

| Rol | Usuario | Contraseña |
|---|---|---|
| Administración | `admin` | `admin123` |
| Operación | `operador` | `operador123` |
| Auditoría | `auditor` | `auditor123` |

La pantalla de login también tiene botones de acceso rápido para cada rol.

## Datos iniciales

La semilla crea:

- 14 clientes en cuatro zonas.
- 8 productos y 16 ubicaciones, incluidas zonas especiales.
- 15 pedidos: 9 listos para ruta, 2 asignados, 3 con historial y 1 en borrador para picking.
- 4 vehículos y 4 conductores.
- 3 proveedores y 3 órdenes de compra de ejemplo.
- 1 recepción con incidencia registrada (la foto se captura al recibir).
- 2 rutas: una histórica y una planificada para despachar.

Las fechas se generan al cargar los datos iniciales. Si operas el sistema otro día y quieres que «hoy» tenga rutas, recrea el volumen o vuelve a ejecutar la carga inicial.

# Navegación del panel

La barra lateral contiene las secciones de trabajo. La barra superior tiene búsqueda por guía, notificaciones y perfil.

| Sección | Uso principal |
|---|---|
| **Inicio** | KPIs del día, rutas recientes, picking, empaque, mermas y productividad |
| **Rutas y reparto** | Generar/replanificar, ver mapa, despachar y consultar paradas |
| **Rastreo** | Línea de tiempo de una guía |
| **Recepción** | Citas/OC, recepción, lotes e incidencias |
| **Picking / Packing** | Ola, surtido, empaque, etiquetas y QC |
| **Inventario** | Stock, movimientos, traslados y zonas |
| **Maestros** | Clientes, productos, ubicaciones, lotes, proveedores y pedidos |
| **Flota** | Vehículos, conductores e historial de rutas |
| **Auditoría** | Bitácora, conteos cíclicos y rotación |
| **Usuarios** | Altas, edición, puestos y activación |
| **Reportes** | Exportación PDF/XLSX |
| **Mi perfil** | Rol, permisos, estado de la API y cierre de sesión |

## Elementos comunes

- **Toasts:** mensajes breves en la esquina inferior derecha. Los verdes confirman; los rojos explican un rechazo.
- **Modales:** formularios de alta, recepción, surtido, entrega y etiquetas. Se cierran con el botón **X**, con `Esc` o haciendo clic fuera.
- **Filtros:** las rutas se filtran por todas, planificadas, en ruta, completadas o canceladas.
- **Búsqueda:** el campo superior busca por guía y abre la sección **Rastreo**.

> **Nota.** Si una acción crítica falla, el modal permanece abierto y muestra el error. No se cierra automáticamente para que puedas corregir sin perder lo capturado.

# Operación diaria

## Maestros

La página **Maestros** concentra el CRUD de datos base.

1. Entra a **Maestros**.
2. Elige la pestaña: Clientes, Productos, Ubicaciones, Lotes, Proveedores o Pedidos.
3. Usa **Nuevo** para crear o **Editar** para modificar.
4. Para desactivar un maestro, edítalo y desmarca **Activo**. No se borra el historial.

### Pedido nuevo

1. **Pedidos → Nuevo pedido**.
2. Selecciona cliente, prioridad y fecha compromiso.
3. Agrega una o más líneas con producto y cantidad.
4. Guarda. El pedido nace en **BORRADOR**.
5. Desde **Picking / Packing** aparecerá como pendiente de ola.

> **Consejo.** Editar un pedido solo es posible mientras esté en BORRADOR. Después de generar la ola, el flujo normal es picking, empaque y QC.

## Recepción

### Programar una cita u orden de compra

1. **Recepción → Nueva OC / cita**.
2. Selecciona proveedor, fecha, hora estimada, andén y observaciones.
3. Agrega los productos esperados con sus cantidades.
4. Guarda. La OC queda **PROGRAMADA**.

### Recibir mercancía

1. En la tabla de OC, pulsa **Recibir**.
2. Para cada línea, verifica solicitado, recibido y pendiente.
3. Captura:
   - Cantidad recibida.
   - Lote.
   - Caducidad.
   - Condición: BUENO, DAÑADO o INCOMPLETO.
   - Ubicación de destino.
4. Usa **Sugerir** si quieres que el sistema proponga una posición GENERAL con menor existencia.
5. Si hay daño o diferencia, marca **Registrar incidencia**, escribe la descripción, el comentario y adjunta una foto.
6. Confirma la recepción.

Al guardar:

- Se inserta el movimiento de entrada.
- El trigger actualiza `almacen.stock` en tiempo real.
- Se crea o actualiza el lote.
- La OC cambia a **RECIBIDA** o **CON_INCIDENCIA**.
- La incidencia queda con responsable, comentario y, si se adjuntó, foto.

> **Advertencia.** Una línea no puede recibir más de lo pendiente. Si la OC ya está completa, el sistema rechaza la recepción.

## Picking y packing

### Generar la ola

1. **Picking / Packing → Generar ola**.
2. El sistema toma todos los pedidos en BORRADOR.
3. Busca stock en zona GENERAL y crea tareas ordenadas por pasillo y `orden_picking`.
4. Los pedidos pasan a **EN_PICKING**.

### Surtir una tarea

1. Pulsa **Surtir** en el pedido.
2. Abre la tarea pendiente.
3. Escanea o escribe el SKU y la ubicación.
4. Puedes usar **Simular escaneo correcto** para validar el flujo.
5. Confirma.

Si el SKU o la ubicación no coinciden, el sistema responde con un error y no descuenta stock. Al completar todas las tareas del pedido, este pasa a **PICKING_COMPLETO**.

### Empacar y etiquetar

1. Con el pedido en PICKING_COMPLETO, pulsa **Empacar**.
2. El sistema genera un empaque y uno o más bultos con guía `LX-…`.
3. Se abre el visor de etiquetas.
4. Revisa cliente, dirección, guía, peso, volumen y total de bultos.
5. Usa **Imprimir etiquetas** para abrir la versión imprimible.

> **Nota.** El código de barras de la etiqueta es visual en esta versión. Para una siguiente fase se recomienda generar Code128 o QR escaneable.

### Aprobar control de calidad

1. Con el pedido **EMPACADO**, pulsa **Aprobar QC**.
2. El empaque queda **VALIDADO**.
3. El pedido queda **LISTO** y puede entrar a una ruta.

## Rutas y reparto

### Generar el plan

1. **Rutas y reparto → Generar plan**.
2. El sistema toma pedidos LISTOS sin ruta activa.
3. Consolida por zona, tipo de cliente, prioridad, peso y volumen.
4. Asigna vehículo y conductor.
5. Optimiza el orden de paradas.
6. Muestra distancia, ahorro, ETA y mapa.

**Replanificar** cancela las rutas PLANIFICADAS del día y vuelve a consolidar. Las rutas en calle o completadas no se tocan.

### Abrir mapa y paradas

1. Pulsa **Mapa y paradas** en una tarjeta de ruta.
2. Revisa la secuencia, cliente, dirección, ETA y bultos.
3. El mapa PNG muestra el CEDIS, las paradas numeradas y las métricas.

### Despachar

1. En una ruta PLANIFICADA, pulsa **Despachar**.
2. Escanea o pega todas las guías.
3. Usa **Simular escaneo completo** para validar el flujo.
4. Confirma.

El sistema rechaza si falta una guía o si se escaneó mercancía de otra ruta. Si todo coincide, la ruta pasa a **EN_RUTA**.

## Entregas

### Entrega exitosa

1. En una ruta EN_RUTA, abre **Mapa y paradas**.
2. Pulsa **Entrega** en la parada pendiente.
3. Elige **Entregado**.
4. Captura el nombre de quien recibió.
5. Firma en el recuadro con mouse o dedo.
6. Adjunta una foto si lo deseas.
7. Guarda la evidencia.

La firma es obligatoria para confirmar la entrega. La evidencia queda asociada a la parada y a cada bulto.

### Entrega fallida

1. Elige **Entrega fallida**.
2. Selecciona el motivo:
   - Cliente cerrado.
   - Dirección incorrecta.
   - Rechazo.
   - Otro.
3. Indica una fecha de reprogramación si aplica.
4. Agrega un comentario.
5. Guarda.

Los bultos pasan a **DEVUELTO**, el pedido a **REPROGRAMADO** o **FALLIDO** y la ruta continúa. El evento queda en el rastreo.

## Rastreo

1. Escribe la guía en **Rastreo** o en la barra superior.
2. Presiona **Enter**.
3. Consulta:
   - Estado actual del paquete.
   - Cliente, pedido, zona y ruta.
   - Peso y volumen.
   - Línea de tiempo de eventos.

> **Consejo.** En la semilla puedes probar `LX-00011` (entrega histórica), `LX-00031` (fallida/reprogramada) o `LX-00071` (ruta planificada).

## Inventario

### Registrar movimiento

1. **Inventario → Registrar movimiento** o **Inicio → Movimiento de inventario**.
2. Selecciona producto y ubicación.
3. Elige ENTRADA o SALIDA.
4. Indica cantidad.
5. Guarda.

La tabla **Movimientos de almacén** se actualiza y el stock se ajusta por trigger. El auditor puede leer, pero no crear movimientos.

### Traslado interno

1. **Inventario → Traslado interno**.
2. Selecciona producto, origen, destino y cantidad.
3. Agrega un comentario.
4. Registra.

El sistema valida stock en origen y crea dos movimientos: SALIDA del origen y ENTRADA al destino. El stock total no cambia. El traslado queda en la tabla y en la bitácora.

### Zonas

Las ubicaciones tienen un tipo de zona:

- GENERAL: almacenamiento y picking normal.
- DEVOLUCIONES: mercancía devuelta.
- DANADOS: producto dañado.
- BLOQUEADO: producto retenido por calidad.
- RESERVADO: producto reservado para un cliente.

El picking solo toma stock de zona GENERAL.

## Auditoría

### Conteo cíclico

1. **Auditoría → Registrar conteo**.
2. Selecciona producto y ubicación.
3. Captura la cantidad física.
4. Guarda.

El sistema obtiene la cantidad del sistema, calcula la diferencia y registra al auditor. Las diferencias negativas alimentan el KPI de mermas del día.

### Bitácora y rotación

- **Bitácora:** acciones por usuario, rol, entidad y detalle. Se puede filtrar.
- **Rotación:** entradas y salidas acumuladas por producto.

La bitácora es inmutable: no se edita ni se borra desde el panel.

## Usuarios

Solo el rol Administración puede gestionar cuentas.

1. **Usuarios → Nuevo usuario**.
2. Captura nombre, usuario, correo, contraseña, rol y puesto.
3. Guarda.
4. Usa **Editar** para cambiar nombre, correo, rol, puesto o contraseña.
5. Usa **Activar/Desactivar** para la baja lógica.

El sistema impide desactivar la última cuenta de administración activa.

## Reportes

1. **Reportes**.
2. Ajusta el periodo si el reporte lo usa.
3. Pulsa **PDF** o **Excel**.

Tipos disponibles:

- Inventario por producto.
- Movimientos de almacén.
- Rutas y desempeño.
- Entregas y evidencias.
- Bitácora.
- Rotación.
- Usuarios.

Si un rol no tiene permiso, el backend responde `403` y el panel muestra el error.

# Referencia rápida

## Estados de pedido

| Estado | Significado |
|---|---|
| BORRADOR | Editable, pendiente de ola |
| EN_PICKING | Tareas de surtido generadas |
| PICKING_COMPLETO | Todo el pedido fue surtido |
| EMPACADO | Bultos y etiquetas generados, esperando QC |
| LISTO | Aprobado por QC, disponible para ruta |
| ASIGNADO | Incluido en una ruta planificada |
| EN_RUTA | Unidad despachada |
| ENTREGADO | Entrega confirmada |
| FALLIDO | Intento fallido sin reprogramación |
| REPROGRAMADO | Intento fallido con nueva fecha |
| CANCELADO | Pedido cancelado |

## Estados de ruta y parada

| Ruta | Significado |
|---|---|
| PLANIFICADA | Armada, pendiente de despacho |
| EN_RUTA | Despachada y validada |
| COMPLETADA | Todas las paradas resueltas |
| CANCELADA | Cancelada por replanificación |

| Parada | Significado |
|---|---|
| PENDIENTE | Sin resultado |
| ENTREGADO | Entrega confirmada |
| FALLIDO | Intento fallido |

## Órdenes de compra

| Estado | Significado |
|---|---|
| PROGRAMADA | Cita creada, pendiente de recibir |
| EN_RECEPCION | Recepción parcial |
| RECIBIDA | Recepción completa |
| CON_INCIDENCIA | Recepción con daño o diferencia |
| CANCELADA | Cita cancelada |

## Snippets de API

Login:

```bash
curl -s http://127.0.0.1:8000/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"usuario":"admin","contrasena":"admin123"}'
```

Generar plan:

```bash
curl -X POST 'http://127.0.0.1:8000/api/rutas/generar?replanificar=false' \
  -H "Authorization: Bearer $TOKEN"
```

Rastreo:

```bash
curl -s http://127.0.0.1:8000/api/rastreo/LX-00011 \
  -H "Authorization: Bearer $TOKEN"
```

Reporte PDF de rutas:

```bash
curl -s 'http://127.0.0.1:8000/api/reportes/exportar?tipo=rutas&formato=pdf' \
  -H "Authorization: Bearer $TOKEN" -o rutas.pdf
```

La documentación interactiva con todos los endpoints está en `http://127.0.0.1:8000/docs`.

# Solución de problemas

| Síntoma | Causa probable | Acción |
|---|---|---|
| PostgreSQL no arranca o «permission denied» en init | Volumen viejo o intento anterior fallido | `sudo docker compose down -v` y `up --build` |
| Puerto 5432 u 8000 ocupado | Otro servicio usa el puerto | Cambia el mapeo en `compose.yaml` |
| «API sin conexión» | Contenedor API detenido o DB no lista | `docker compose ps` y `logs -f api` |
| Login rechazado | Credenciales o cuenta inactiva | Usa una cuenta inicial; revisa Usuarios |
| «No hay stock suficiente en zona GENERAL» | Stock en zona especial o insuficiente | Revisa Inventario; recibe mercancía o mueve stock a GENERAL |
| «El SKU escaneado no corresponde» | Se capturó otro producto | Revisa la tarea y usa el SKU/ubicación indicados |
| «La ruta no puede despacharse» | Ya está EN_RUTA/COMPLETADA | Consulta el estado en la tarjeta |
| Despacho rechazado por faltantes | Falta escanear una guía | Vuelve a escanear todas las guías |
| Despacho rechazado por «ajenas» | Se escaneó mercancía de otra ruta | Retira esa guía y valida solo las de la ruta |
| No se abren las etiquetas | Bloqueo de ventanas emergentes | Permite popups para `127.0.0.1` |
| Un reporte devuelve 403 | El rol no tiene permiso | Prueba con Administración u otro tipo de reporte |
| La evidencia no aparece | Archivo movido o borrado | Revisa `royal-back/data/evidencias` |
| La fecha de los datos está vieja | Carga inicial ejecutada otro día | Recrea el volumen o vuelve a ejecutar la carga inicial |

> **Nota.** Si el error persiste, revisa `docker compose logs -f api` y `docker compose logs -f db`. El backend devuelve mensajes en español y registra las acciones en la bitácora.

# Glosario

| Término | Definición |
|---|---|
| **Andén** | Rampa de carga o descarga del CEDIS |
| **Bulto** | Paquete físico identificado por una guía |
| **CEDIS** | Centro de distribución |
| **Consolidación** | Agrupación de pedidos por zona, tipo y capacidad |
| **Diferencia** | Físico menos sistema en un conteo |
| **ETA** | Tiempo estimado de llegada a una parada |
| **Evidencia** | Firma o foto que respalda una entrega |
| **Guía** | Identificador único de un bulto para rastreo |
| **Lote** | Conjunto de producto con caducidad y condición |
| **OC** | Orden de compra |
| **PEPS/FIFO** | Primero en entrar, primero en salir |
| **Picking** | Surtido de productos para un pedido |
| **Putaway** | Acomodo de mercancía recibida en su ubicación |
| **QC** | Control de calidad previo al embarque |
| **Ruta** | Viaje con vehículo, conductor y paradas |
| **SKU** | Identificador de producto |
| **Tarima** | Plataforma de carga |
| **Zona** | Agrupación geográfica de clientes o tipo de ubicación |

# Buenas prácticas y limitaciones

## Buenas prácticas

- Cambia `ROYAL_SECRETO` y las cuentas iniciales antes de exponer el sistema.
- No expongas PostgreSQL ni la API fuera de loopback sin TLS y reglas de firewall.
- Recrea el volumen después de cambios de esquema.
- Usa el rol Auditoría para revisar, no para operar.
- Registra los conteos con la cantidad física real; la diferencia es evidencia.
- Revisa la bitácora después de una operación crítica.

## Limitaciones de la versión

- El código de barras es visual; no se genera un estándar escaneable.
- PEPS/FIFO no descuenta lotes por caducidad de forma estricta.
- El QC no tiene flujo de rechazo con reempaque.
- Las auditorías no se separan por supervisor/calidad/dirección.
- No hay job automático que reprograme pedidos a LISTO.
- La evidencia se guarda en disco local.
- No hay PWA/offline ni cámara móvil.
- Los tokens no se revocan al desactivar una cuenta; expiran por tiempo.

# Véase también

- `README.md` — instalación, arquitectura y comandos.
- `docs/VALIDACION_REQUERIMIENTOS.md` — matriz de cumplimiento y CRUD.
- `http://127.0.0.1:8000/docs` — documentación interactiva de la API.
- `bruno/Royal Express` — colección de peticiones de API.
- `royal-back/scripts/validar_e2e.py` — validación end-to-end.
