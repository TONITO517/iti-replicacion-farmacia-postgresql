# Guion para exponer el sistema de replicación de farmacia

Presentación breve para un grupo universitario de Ingeniería de Sistemas. Completar los nombres de integrantes y ajustar el tiempo al indicado por el docente.

## Diapositiva 1 - Sistema de farmacias

**En pantalla:** Replicación bidireccional de PostgreSQL para dos sucursales de farmacia. Integrantes, curso y docente.

**Qué explicar:** Presentar el caso como una demostración académica con dos sucursales y datos ficticios. Completar en la portada los nombres del grupo.

## Diapositiva 2 - Problema y objetivo

**En pantalla:** Cada sucursal necesita registrar ventas aunque no esté conectada a la otra; ambas requieren consultar la información compartida.

**Qué explicar:** El objetivo es observar cómo los cambios de una sede llegan a la otra y qué límites aparecen.

## Diapositiva 3 - Tecnología elegida

**En pantalla:** PostgreSQL 18.6, replicación lógica nativa, dos clústeres locales y pgAdmin 4.

**Qué explicar:** PostgreSQL ya está instalado y ofrece publicaciones y suscripciones para replicar tablas. pgAdmin sirve para administrar las conexiones. Los dos clústeres usan carpetas y puertos separados.

## Diapositiva 4 - Arquitectura

**En pantalla:** Diagrama editable de dos nodos activos con flechas de replicación en ambos sentidos y conexión administrativa de pgAdmin.

**Qué explicar:** Nodo A publica y recibe cambios desde Nodo B, y viceversa. La replicación es asíncrona. La prueba se ejecutó en dos instancias dentro de una PC, así que no representa dos sedes físicas.

## Diapositiva 5 - Modelo y prevención de conflictos

**En pantalla:** Sucursal, medicamento, inventario, venta y detalle de venta, con UUID para identificar las ventas.

**Qué explicar:** Cada sucursal modifica sus propias filas de inventario. Las ventas usan UUID. Si se intenta modificar la misma fila de manera incompatible, PostgreSQL puede pausar la aplicación y requiere una decisión explícita.

## Diapositiva 6 - Demostración y resultados

**En pantalla:** Las dos ventas de demostración y sus detalles aparecen en ambos nodos; 0 filas huérfanas; carga de 100 ventas con 66.9 ms de convergencia observada.

**Qué explicar:** Resumir que los cambios de A llegaron a B y los de B llegaron a A. La medición de 66.9 ms es de una sola ejecución y contiene el tiempo de sondeo y de invocar el cliente; no es latencia pura de red.

## Diapositiva 7 - Conclusiones

**En pantalla:** La replicación lógica permite compartir cambios con retraso. Requiere reglas de escritura y un procedimiento de recuperación de conflictos.

**Qué explicar:** Mencionar que la demostración no incluye failover transparente y usa dos nodos locales. Una instalación real necesita revisar disponibilidad, seguridad, monitoreo, respaldos y reglas para resolver conflictos.

## Diapositiva 8 - Referencias

**En pantalla:** Documentación oficial de PostgreSQL 18 sobre replicación lógica, suscripciones y conflictos; enunciado del curso.

**Qué explicar:** Indicar que la configuración y los límites descritos se contrastaron con la documentación oficial de PostgreSQL 18. El proyecto usa exclusivamente datos de muestra.
