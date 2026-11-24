# Conflictos y recuperación

## Cómo reducimos conflictos en la operación normal

Las dos sucursales registran ventas con UUID, por lo que no dependen de secuencias sincronizadas. Cada una actualiza solamente las filas de inventario de su propio `sucursal_id`; eso evita que las ventas rutinarias de ambas sedes escriban simultáneamente la misma fila de stock.

El catálogo se considera administrado centralmente durante la demo. Se evita editar la misma fila de medicamento a la vez en los dos nodos. Estas reglas reducen conflictos, pero no impiden que un operador conectado directamente a pgAdmin rompa la convención.

## Qué hace PostgreSQL si ocurre un conflicto

En replicación lógica nativa, un cambio remoto que infringe una restricción (por ejemplo, una clave primaria duplicada) puede detener el worker de aplicación de esa suscripción. PostgreSQL registra el conflicto en los logs y permite ver estadísticas en `pg_stat_subscription_stats`. No se debe asumir una política automática de “gana el último” para todo tipo de conflicto.

## Prueba controlada y recuperación

La prueba usa dos medicamentos ficticios con UUID diferentes, pero el mismo `codigo` único. Solo debe ejecutarse en la base descartable del proyecto.

1. En Nodo A, deshabilitar la suscripción `sub_desde_nodo_b`. En Nodo B, deshabilitar `sub_desde_nodo_a`.
2. Ejecutar `database/conflicto_nodo_a.sql` en Nodo A y `database/conflicto_nodo_b.sql` en Nodo B.
3. Habilitar ambas suscripciones. Cada nodo intentará recibir el medicamento de la otra sucursal y el worker chocará con la restricción única `medicamento_codigo_key`.
4. Revisar el registro con `docker compose logs nodo-a nodo-b` y `pg_stat_subscription_stats` en pgAdmin. Guardar la evidencia del error.
5. Deshabilitar otra vez ambas suscripciones. En Nodo A, cambiar el código local a `MED-DUP-CONFLICTO-A`; en Nodo B, cambiarlo a `MED-DUP-CONFLICTO-B`.
6. Habilitar las dos suscripciones y esperar a que procesen los cambios pendientes.
7. Consultar la tabla `medicamento` en ambos nodos. Deben existir los dos UUID, con códigos distintos, y las dos suscripciones deben estar activas.

La reparación conserva ambos medicamentos ficticios y resuelve la colisión de la clave de negocio cambiando los códigos para que sean únicos. Si un conflicto involucra ventas reales, se debe decidir con el responsable del negocio; no borrar ni alterar una venta para ocultar el error.

Después de guardar capturas y resultados, se pueden limpiar las dos filas de prueba eliminando cada UUID una sola vez desde cualquiera de los nodos y comprobando que ambas eliminaciones se replican.

## Límites

La replicación bidireccional lógica no equivale a replicación síncrona con consenso. Puede haber retraso durante desconexiones, y la consistencia final depende de restricciones, reglas de escritura y resolución de conflictos. La arquitectura es una demostración de curso, no una recomendación para operar una farmacia real.
