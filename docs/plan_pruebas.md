# Plan de evaluación y pruebas

Las pruebas se realizarán con datos ficticios en los dos nodos locales. Antes de publicar resultados en el informe, se guardará evidencia reproducible (consultas, salida de comandos y capturas de pgAdmin).

| ID | Escenario | Procedimiento | Resultado esperado |
|---|---|---|---|
| P01 | Estado inicial | Consultar nodos, publicaciones y suscripciones después del inicio | Ambos servidores están activos y cada uno tiene una suscripción habilitada |
| P02 | A hacia B | Ejecutar `demo_sucursal_a.sql` en Nodo A y consultar la venta en B | La venta y su detalle aparecen en B; el inventario de Sucursal A coincide |
| P03 | B hacia A | Ejecutar `demo_sucursal_b.sql` en Nodo B y consultar la venta en A | La venta y su detalle aparecen en A; el inventario de Sucursal B coincide |
| P04 | Integridad relacional | Consultar ventas con sucursal y líneas con medicamento | No hay registros huérfanos; las claves foráneas se conservan |
| P05 | Escrituras simultáneas separadas | Ejecutar `scripts/prueba-concurrente.ps1`, que inicia dos inserciones en paralelo | Ambas ventas llegan a los dos nodos y no chocan por UUID |
| P06 | Interrupción temporal | Detener Nodo B, insertar una venta en A, volver a iniciar B | Al restablecer conexión, el cambio pendiente llega a B |
| P07 | Conflicto de clave única | Insertar medicamentos con UUID distintos y el mismo código en ambos nodos con suscripciones deshabilitadas; habilitarlas | Los workers reportan conflicto por el código duplicado y se conserva evidencia |
| P08 | Recuperación del conflicto | Deshabilitar, asignar un código único a cada medicamento y volver a habilitar las suscripciones | Ambos nodos terminan con las dos filas y los workers continúan |
| P09 | Medición básica de rendimiento | Ejecutar `scripts/medir-replicacion.ps1` con 100 filas y guardar el CSV generado | Se registran filas, tiempo de inserción local y tiempo observado hasta convergencia; se describe el límite del método |

## Registro de resultados

| ID | Fecha | Resultado | Evidencia | Observaciones |
|---|---|---|---|---|
| P01 | Aprobada | Dos suscripciones habilitadas en ambos nodos | Consultas `pg_subscription` | Los puertos 5433 y 5434 responden. |
| P02-P03 | Aprobadas | Dos ventas y dos detalles visibles en ambos nodos | Consultas `venta` y `detalle_venta` | Se ejecutaron los archivos de demostración en A y B. |
| P04 | Aprobada | 0 filas huérfanas en cada nodo | Consulta de integridad referencial | Se comprobaron sucursal, venta y medicamento. |
| P05 | Aprobada | Dos ventas insertadas en paralelo convergieron en cada nodo | Marcador `P05-7677ce454227485694e132f5cd79b3cf` | Las dos filas de demostración permanecen en ambos nodos para poder inspeccionarlas. |
| P06 | Aprobada | Venta de A llegó a B tras detener y reiniciar B | UUID `30000000-0000-4000-8000-000000000001` observado en B | Prueba local controlada. |
| P07-P08 | Aprobadas | Conflicto por código duplicado detectado y luego resuelto | `pg_stat_subscription_stats`; ambos UUID convergieron con códigos únicos | Las filas de prueba se limpiaron después. |
| P09 | Aprobada | 100 ventas llegaron a B | `informe/resultados_rendimiento.csv` | Inserción local 78.5 ms; convergencia observada 66.9 ms. Una sola muestra y con sobrecosto del sondeo/cliente. |

No se inventarán mediciones de latencia o disponibilidad. Si se solicita una medida de rendimiento, se registrarán el tamaño de muestra, el comando, el tiempo observado y el hardware utilizado.
