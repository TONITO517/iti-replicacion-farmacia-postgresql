# Guion para la presentación oral

Presentación breve para un grupo universitario de Ingeniería de Sistemas. Completar los nombres de integrantes y ajustar el tiempo al indicado por el docente.

## Diapositiva 1 - Título

**En pantalla:** Replicación bidireccional de PostgreSQL para dos sucursales de farmacia. Integrantes, curso y docente.

**Qué explicar:** Presentar el problema y aclarar que es una demostración académica con datos ficticios.

## Diapositiva 2 - Problema y objetivo

**En pantalla:** Cada sucursal necesita registrar ventas aunque no esté conectada a la otra; ambas requieren consultar la información compartida.

**Qué explicar:** El objetivo es observar cómo los cambios de una sede llegan a la otra y qué límites aparecen.

## Diapositiva 3 - Tecnología elegida

**En pantalla:** PostgreSQL 16, replicación lógica nativa, Docker Compose y pgAdmin 4.

**Qué explicar:** PostgreSQL se eligió por su replicación lógica, documentación y herramientas accesibles. pgAdmin administra las instancias; Docker las ejecuta separadas.

## Diapositiva 4 - Arquitectura

**En pantalla:** Diagrama de dos nodos activos, uno por sucursal, con flechas de replicación en ambos sentidos. pgAdmin conectado a ambos.

**Qué explicar:** Cada nodo publica sus tablas y se suscribe al otro. La sincronización es asíncrona. Son dos instancias dentro de una PC para la demo.

## Diapositiva 5 - Modelo y prevención de conflictos

**En pantalla:** Tablas sucursal, medicamento, inventario, venta y detalle_venta.

**Qué explicar:** Cada sucursal modifica sus propias filas de inventario. Las ventas usan UUID. Si se intenta modificar la misma fila de manera incompatible, PostgreSQL puede pausar la aplicación y requiere una decisión explícita.

## Diapositiva 6 - Demostración y resultados

**En pantalla:** Capturas de la venta de Sucursal A vista en Nodo B y la venta de Sucursal B vista en Nodo A; resumen del plan de pruebas.

**Qué explicar:** Ejecutar la consulta en pgAdmin y comparar los nodos. Completar esta diapositiva solo con capturas y resultados reales.

## Diapositiva 7 - Conclusiones

**En pantalla:** La replicación mantiene copias sincronizadas con retraso; las reglas de escritura ayudan a evitar conflictos; hacen falta monitoreo y recuperación.

**Qué explicar:** Resumir el aprendizaje y mencionar que esta demo no incluye failover transparente ni debe usarse para datos reales de salud.
