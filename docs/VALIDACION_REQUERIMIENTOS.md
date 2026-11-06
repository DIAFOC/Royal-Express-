# Validación de requerimientos · LogistiXpress

**Fecha:** 6 de noviembre de 2026  
**Alcance:** versión 1.0 de Royal Express.  
**Referencia:** *Solicitud de desarrollo de software para centro de distribución y logística “LogistiXpress”*.

## Leyenda

| Estado | Significado |
|---|---|
| ✅ | Implementado y verificable en la aplicación |
| 🟡 | Implementado con una decisión de alcance de la versión 1.0 |
| ❌ | No implementado |

---

## 1. Resumen ejecutivo

La versión actual ya no es solo el módulo 4: cubre el **flujo operativo completo** del documento con un nivel operativo.

- **Maestros:** CRUD de clientes, productos, ubicaciones, lotes, proveedores y pedidos.
- **Recepción:** citas/OC con proveedor, fecha, hora y andén; recepción por línea; lote, caducidad y condición; entrada de stock por trigger; incidencias con foto y responsable.
- **Acomodo:** ubicaciones con pasillo/rack/nivel, zonas especiales y sugerencia de putaway.
- **Picking/packing:** ola de picking ordenada por pasillo, validación de SKU/ubicación, empaque con guías, etiquetas imprimibles y aprobación de QC.
- **Inventario:** stock en vivo, movimientos, traslados origen→destino y alertas de mínimos.
- **Reparto:** rutas consolidadas, mapa PNG, despacho con escaneo, entrega con firma/foto, entregas fallidas y rastreo por guía.
- **Panel:** ocupación, pedidos pendientes/en picking/en empaque/en ruta, productividad de picking, stock bajo, productos estancados y mermas del día.
- **Seguridad:** tres roles (`admin`, `operador`, `auditor`) más un campo `puesto` descriptivo para los tipos de usuario del documento; RBAC en FastAPI y `SET LOCAL ROLE` en PostgreSQL; bitácora completa.

### Decisiones de alcance de la versión 1.0

- No hay lector de código de barras físico integrado: los formularios aceptan captura/escaneo por teclado y el escaneo se **valida contra SKU/ubicación**.
- PEPS/FIFO está modelado con lotes y caducidad, pero el picking prioriza pasillo/orden de ubicación; no descuenta lotes por caducidad estricta.
- El control de calidad aprueba el empaque; no existe un flujo separado de rechazo con reempaque.
- Las auditorías usan el rol auditor, bitácora y conteos; no hay tipos formales “supervisor/calidad/dirección” con aprobación por área.
- Las etiquetas imprimen un código visual; no se genera un Code128 real escaneable.
- No hay PWA/offline ni cámara de celular para códigos.

---

## 2. Matriz requisito por requisito

### 1. Recepción de mercancía y descarga en andenes

| Requisito | Estado | Evidencia |
|---|---|---|
| Registrar OC esperadas, proveedor, hora estimada y andén | ✅ | `operaciones.ordenes_compra`; página **Recepción**; `POST /api/recepcion/ordenes`. |
| Escanear tarimas/cajas/lotes y comparar contra OC; alertar faltantes/rotos/incorrectos | 🟡 | Recepción por línea valida cantidades pendientes contra la OC, captura lote/condición y genera incidencia. El escaneo es captura por teclado/SKU, no lector físico. |
| Capturar lote, caducidad y condición (bueno/dañado/incompleto) | ✅ | `almacen.lotes`; recepción y maestro de lotes; condición `BUENO/DANADO/INCOMPLETO`. |
| Incidencias de recepción con fotos, responsable y comentarios | ✅ | `operaciones.incidencias_recepcion`; foto opcional, responsable y comentario; endpoint de foto. |

### 2. Acomodo y ubicación en racks

| Requisito | Estado | Evidencia |
|---|---|---|
| Mapeo de pasillo, rack, nivel y posición; indicar dónde colocar tarima | ✅ | Maestro de ubicaciones; `GET /api/recepcion/sugerir-ubicacion` sugiere una posición GENERAL activa. |
| Inventario en vivo disponible para venta/surtido | ✅ | Trigger `fn_actualizar_stock_tiempo_real`; movimientos y traslados actualizan stock al instante. |
| PEPS/FIFO por lote antiguo o caducidad próxima | 🟡 | Lotes y caducidad; el picking ordena por pasillo/`orden_picking`, no fuerza consumo por caducidad. |
| Reubicaciones y traspasos con origen/destino | ✅ | `almacen.traslados`; UI **Inventario → Traslado interno**; dos movimientos SALIDA/ENTRADA y auditoría. |
| Zonas especiales: devoluciones, dañado, bloqueado, reservado | ✅ | `ubicaciones.tipo_zona`; ubicaciones `DEV-01-1`, `DAN-01-1`, `BLO-01-1`, `RES-01-1`; el picking solo toma de GENERAL. |

### 3. Preparación de pedidos (Picking y Packing)

| Requisito | Estado | Evidencia |
|---|---|---|
| Rutas óptimas de recolección agrupando por pasillo | ✅ | `POST /api/picking/generar`; tareas ordenadas por pasillo + `orden_picking`; ola multi-pedido. |
| Picking guiado por escáner con producto, cantidad y ubicación; alerta si es incorrecto | ✅ | Modal de tarea con SKU/ubicación; el backend rechaza si no coincide; botón de simulación. |
| Validación de empaque, cantidades/artículos y alarma | 🟡 | El surtido valida producto/ubicación/cantidad; el empaque crea bultos y el QC aprueba. No hay alarma sonora ni estación de empaque separada. |
| Etiquetado con código, peso, guía, cliente y total de bultos | ✅ | `POST /api/picking/pedidos/{id}/empacar` genera bultos/guías; modal de etiquetas imprimibles con peso, volumen, cliente y total. |
| Control de calidad previo al embarque por supervisor | ✅ | `POST /api/picking/pedidos/{id}/aprobar`; empaque VALIDADO y pedido LISTO; queda en bitácora. |

### 4. Embarques, rutas y control de flota

| Requisito | Estado | Evidencia |
|---|---|---|
| Consolidar por zona, tipo de cliente, peso y volumen | ✅ | `app/servicios/planificador.py`; agrupa por zona, prioriza tipo de cliente y valida capacidades. |
| Despacho: escanear todos los bultos, validar faltantes y mercancía ajena | ✅ | `POST /api/rutas/{id}/despachar`; modal de escaneo y validación de faltantes/ajenas. |
| Placas, chofer, capacidad e historial de rutas | ✅ | `vehiculos`, `conductores`, `rutas`; UI de flota con edición/desactivación e historial. |
| Comprobante: marcar entrega, firma, foto y nombre de quien recibe | ✅ | Modal responsive; firma en canvas, foto y nombre; evidencia servida con autenticación. |
| Entregas fallidas: motivo, reprogramar, devolver a bodega | ✅ | Motivos, fecha de reprogramación, bultos DEVUELTO y pedido REPROGRAMADO/FALLIDO. El regreso automático a LISTO queda como job futuro. |

### 5. Panel de control y auditorías

| Requisito | Estado | Evidencia |
|---|---|---|
| Conteos cíclicos físico vs sistema, mermas | ✅ | `auditoria.conteos_ciclicos`; UI de conteos; diferencia y mermas del día en el panel. |
| Auditorías por supervisor, calidad y dirección | 🟡 | Rol auditor, bitácora y conteos; no hay tipos formales de auditoría ni aprobación por área. |
| Tablero de dirección: ocupación, pendientes, empaque, ruta, productividad, stock bajo, estancado, mermas | ✅ | Panel con KPIs y panel de productividad de picking; consultas nuevas en `RepositorioPanel`. |
| Reportes PDF/Excel, movimientos por producto, rutas/entregas | ✅ | `/api/reportes/exportar`; tipos `inventario`, `movimientos`, `rutas`, `entregas`, `auditoria`, `rotacion`, `usuarios`. |

### 6. Seguridad, roles y accesos

| Requisito | Estado | Evidencia |
|---|---|---|
| Tipos de usuario: auxiliar, montacarguista, surtidor, empacador, chofer, supervisor, administración, dirección | ✅ | Campo `puesto` en usuarios con esos valores; el RBAC sigue en tres roles para no romper el paradigma del proyecto. |
| Permisos: cantidades, borrados, información económica y rutas | ✅ | RBAC en FastAPI + `SET LOCAL ROLE`; no hay endpoints de borrado duro; movimientos/bitácora inmutables; no se modela información económica. |
| Registro de quién movió, ajustó, aprobó y generó rutas | ✅ | `seguridad.bitacora`; login, rutas, despacho, entrega, inventario, recepción, picking, empaque, conteos y usuarios. |

### 7. Acceso y facilidad de uso

| Requisito | Estado | Evidencia |
|---|---|---|
| Computadoras, terminales, tablets y teléfonos | 🟡 | SPA responsive; captura por teclado y puntero/touch. Sin PWA offline ni cámara nativa de códigos. |
| Pantallas claras, botones grandes, procesos guiados y escaneo rápido | ✅/🟡 | Interfaz clara y modales guiados; el escaneo se simula o se captura por teclado. |

### 8. Resumen general

| Requisito | Estado |
|---|---|
| Controlar entradas, salidas y ubicaciones en tiempo real | ✅ |
| Organizar acomodo en racks con precisión | ✅ |
| Generar rutas óptimas de picking | ✅ |
| Validar empaque y etiquetado | ✅/🟡 |
| Gestionar embarques y entregas con evidencia digital | ✅ |
| Permitir auditorías y conteos cíclicos | ✅/🟡 |
| Mostrar métricas de productividad y rotación | ✅ |
| Limitar accesos según rol | ✅ |
| Ser fácil de usar y funcionar en el piso | ✅/🟡 |

---

## 3. Matriz CRUD real

Estados: C = crear, R = leer, U = actualizar, D = borrar.

| Tabla | C | R | U | D | Observación |
|---|---|---|---|---|---|
| `seguridad.usuarios` | ✅ | ✅ | ✅ | 🟡 | Alta, edición de nombre/correo/rol/puesto/contraseña y baja lógica con `activo`. |
| `seguridad.bitacora` | ✅ | ✅ | ❌ | ❌ | Inmutable por diseño. |
| `almacen.productos` | ✅ | ✅ | ✅ | 🟡 | Baja lógica con `activo`; sin borrado físico. |
| `almacen.ubicaciones` | ✅ | ✅ | ✅ | 🟡 | Baja lógica con `activo`; zonas especiales. |
| `almacen.stock` | 🟡 | ✅ | 🟡 | ❌ | Se actualiza por movimientos/traslados, no por CRUD directo. |
| `almacen.lotes` | ✅ | ✅ | ✅ | ❌ | Catálogo de lotes y recepción. |
| `almacen.movimientos` | ✅ | ✅ | ❌ | ❌ | Histórico inmutable. |
| `almacen.traslados` | ✅ | ✅ | ❌ | ❌ | Registro de reubicaciones. |
| `operaciones.clientes` | ✅ | ✅ | ✅ | 🟡 | Baja lógica con `activo`. |
| `operaciones.proveedores` | ✅ | ✅ | ✅ | 🟡 | Baja lógica con `activo`. |
| `operaciones.pedidos` | ✅ | ✅ | ✅ | 🟡 | Edición solo en BORRADOR; cancelación lógica. |
| `operaciones.pedido_detalle` | ✅ | ✅ | ✅ | ✅ | Se reemplazan líneas al editar un BORRADOR. |
| `operaciones.ordenes_compra` | ✅ | ✅ | ✅ | 🟡 | Recepción actualiza; cancelación lógica. |
| `operaciones.recepciones` / líneas | ✅ | ✅ | ❌ | ❌ | Evidencia histórica de recepción. |
| `operaciones.incidencias_recepcion` | ✅ | ✅ | ❌ | ❌ | Evidencia con foto/responsable. |
| `operaciones.bultos` | ✅ | ✅ | ✅ | ❌ | Alta en empaque; estado en despacho/entrega. |
| `operaciones.picking_olas` / tareas | ✅ | ✅ | ✅ | ❌ | Generación y surtido. |
| `operaciones.empaques` | ✅ | ✅ | ✅ | ❌ | Empaque y aprobación QC. |
| `operaciones.vehiculos` / conductores | ✅ | ✅ | ✅ | 🟡 | Edición y baja lógica con `activo`. |
| `operaciones.rutas` / paradas / ruta_bultos | ✅ | ✅ | ✅ | 🟡 | Cancelación lógica; sin borrado físico. |
| `operaciones.entregas` | ✅ | ✅ | ❌ | ❌ | Evidencia histórica. |
| `operaciones.eventos_rastreo` | ✅ | ✅ | ❌ | ❌ | Automático e inmutable. |
| `auditoria.conteos_ciclicos` | ✅ | ✅ | ❌ | ❌ | Evidencia de auditoría. |

**Borrado:** no se exponen borrados duros para movimientos, bitácora, rutas, entregas o evidencias. Es una decisión de integridad y auditoría; los maestros usan baja lógica y los pedidos usan cancelación.

---

## 4. Guion de operación y presentación

### A. Maestros y pedido nuevo

1. Login `admin`.
2. **Maestros → Clientes → Nuevo cliente** (crear).
3. **Productos → Nuevo producto**, **Ubicaciones → Nueva ubicación**.
4. **Proveedores → Nuevo proveedor**.
5. **Pedidos → Nuevo pedido** con dos líneas.
6. Mostrar que el pedido nace en **BORRADOR**.

### B. Recepción

1. **Recepción → Nueva OC / cita**: proveedor, fecha, hora, andén y líneas.
2. **Recibir**: cantidad, lote, caducidad, condición y ubicación sugerida.
3. Mostrar stock actualizado y lote en **Maestros → Lotes**.
4. Repetir con condición **DANADO** y foto; mostrar **Incidencias** y el estado `CON_INCIDENCIA`.

### C. Picking, empaque, etiquetas y QC

1. **Picking / Packing → Generar ola**.
2. Abrir **Surtir** en el pedido; usar “Simular escaneo correcto” o capturar SKU/ubicación.
3. Confirmar todas las tareas.
4. **Empacar** → se generan bultos y guías; mostrar etiquetas e imprimir.
5. **Aprobar QC** → el pedido queda **LISTO**.
6. Ir a **Rutas → Generar plan**: el pedido recién empacado aparece en una ruta.

### D. Reparto, entrega y rastreo

1. Abrir **Rutas → Mapa y paradas**.
2. **Despachar** con una guía faltante (rechazo) y luego con el escaneo completo.
3. Registrar una **entrega** con firma/foto/nombre.
4. Registrar una **entrega fallida** con motivo y reprogramación.
5. **Rastreo**: buscar la guía y mostrar la línea de tiempo.

### E. Inventario, auditoría y reportes

1. **Inventario → Traslado interno**: mover producto de una posición a otra; stock total no cambia.
2. **Inventario → Registrar movimiento**: entrada/salida y ver la bitácora.
3. **Auditoría → Registrar conteo**: físico vs sistema y diferencia.
4. **Reportes**: PDF de rutas, Excel de inventario, PDF de movimientos.
5. Entrar como **auditor**: puede ver y exportar; no puede generar rutas, surtir, empacar ni mover inventario.
6. Entrar como **operador**: puede operar el piso; no ve gestión de usuarios ni auditoría.

---

## 5. Validación ejecutada

```bash
cd royal-back
source .venv/bin/activate
pip install -r requirements-dev.txt
pytest -q
python scripts/validar_e2e.py
```

Resultados de esta versión:

- `10 passed` en pruebas unitarias.
- E2E real con PostgreSQL embebido: login/RBAC, plan de rutas, mapa, despacho con rechazo, entrega con firma, rastreo, movimiento de inventario, conteo, reportes, CRUD de maestros, OC/recepción con lote, incidencia con foto, ola de picking multi-pedido, validación de SKU incorrecto, empaque, QC, reincorporación a rutas, traslado interno y edición de flota/usuarios.
- Panel extendido verificado: picking, empaque, mermas, productividad, recepciones e incidencias.
- UI con jsdom contra API/PostgreSQL reales: 12 secciones, maestros, recepción, ola de picking, surtido, empaque, etiquetas, QC, traslados, flota y usuarios, sin errores JavaScript.

---

## 6. Brechas menores / siguientes pasos

1. **Lector de códigos real**: integrar cámara/lector y generar Code128/QR escaneable.
2. **PEPS/FIFO estricto**: descontar lotes por caducidad y registrar trazabilidad lote→bulto.
3. **QC con rechazo y reempaque**: flujo de rechazo con motivo y nueva etiqueta.
4. **Auditorías por área**: tipos supervisor/calidad/dirección y aprobación.
5. **Job de reprogramación**: devolver pedidos REPROGRAMADO a LISTO en la fecha.
6. **PWA/offline** y captura móvil de códigos.
7. **Object storage** para evidencias en despliegues multi-instancia.
8. **Token revocation** al desactivar usuarios.

Con esto, Royal Express cubre el documento completo a nivel funcional y deja claras las decisiones de alcance.
