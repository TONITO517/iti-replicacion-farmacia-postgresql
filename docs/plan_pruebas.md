# Plan de evaluación y pruebas

Las pruebas se realizarán con datos ficticios en los dos nodos locales. Antes de publicar resultados en el informe, se guardará evidencia reproducible (consultas, salida de comandos y capturas de pgAdmin).

| ID | Escenario | Procedimiento | Resultado esperado |
|---|---|---|---|
| P01 | Estado inicial | Consultar nodos, publicaciones y suscripciones después del inicio | Ambos servidores están activos y cada uno tiene una suscripción habilitada |
| P02 | A hacia B | Ejecutar `demo_sucursal_a.sql` en Nodo A y consultar la venta en B | La venta y su detalle aparecen en B; el inventario de Sucursal A coincide |
| P03 | B hacia A | Ejecutar `demo_sucursal_b.sql` en Nodo B y consultar la venta en A | La venta y su detalle aparecen en A; el inventario de Sucursal B coincide |
| P04 | Integridad relacional | Consultar ventas con sucursal y líneas con medicamento | No hay registros huérfanos; las claves foráneas se conservan |
| P05 | Escrituras simultáneas separadas | Crear una venta en A para su sucursal y otra en B para su sucursal | Ambas ventas llegan a los dos nodos y no chocan por UUID |
| P06 | Interrupción temporal | Detener Nodo B, insertar una venta en A, volver a iniciar B | Al restablecer conexión, el cambio pendiente llega a B |
| P07 | Conflicto de clave única | Insertar medicamentos con UUID distintos y el mismo código en ambos nodos con suscripciones deshabilitadas; habilitarlas | Los workers reportan conflicto por el código duplicado y se conserva evidencia |
| P08 | Recuperación del conflicto | Deshabilitar, asignar un código único a cada medicamento y volver a habilitar las suscripciones | Ambos nodos terminan con las dos filas y los workers continúan |

## Registro de resultados

| ID | Fecha | Resultado | Evidencia | Observaciones |
|---|---|---|---|---|
| P01-P08 | Pendiente | No ejecutado | Pendiente | Se completará cuando el motor Docker esté activo y se haya desplegado la demo. |

No se inventarán mediciones de latencia o disponibilidad. Si se solicita una medida de rendimiento, se registrarán el tamaño de muestra, el comando, el tiempo observado y el hardware utilizado.
