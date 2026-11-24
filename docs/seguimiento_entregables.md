# Seguimiento del enunciado

| Requisito | Trabajo preparado | Estado verificable |
|---|---|---|
| 1. Selección de tecnología | Justificación de PostgreSQL frente a los criterios de replicación, rendimiento, escalabilidad y facilidad de uso en `informe/informe_tecnico.md` | Redactado con evidencia de una medición real; falta confirmar la discrepancia de puntaje de la rúbrica. |
| 2. Diseño de arquitectura | Dos nodos activos, publicación/suscripción, sincronización asíncrona, reglas de conflicto y seguridad en `docs/arquitectura.md` y el informe | Diagrama final disponible en `docs/arquitectura.svg` y en la presentación. |
| 3. Implementación | Dos clústeres PostgreSQL 18 locales, esquema SQL, ejemplos de ventas, inicio, detención y configuración de suscripciones con PowerShell | Ejecutados en puertos 5433 y 5434; la instancia en 5432 se mantiene aparte. |
| 4. Evaluación y pruebas | Pruebas de ida y vuelta, integridad, interrupción, conflicto/recuperación y medición básica | P01-P09 ejecutadas; dos filas concurrentes de P05 permanecen como evidencia en los nodos. Ver `docs/plan_pruebas.md` y CSV de rendimiento. |
| 5. Informe técnico | Informe con problema, elección, arquitectura, implementación, pruebas, conclusiones y recomendaciones | Markdown, DOCX y PDF generados y revisados visualmente; faltan completar integrantes, docente y fecha de entrega. |
| Código fuente | SQL y scripts del proyecto | Preparado en esta carpeta, independiente de `GYM_CONTROL`. |
| Presentación oral | Guion de ocho diapositivas y presentación editable | Preparados con datos de las pruebas ejecutadas. |

## Rúbrica leída del PDF

| Criterio | Puntaje |
|---|---:|
| Conceptos de replicación | 2 |
| Diseño de arquitectura | 2 |
| Implementación | 6 |
| Pruebas y rendimiento | 1 |
| Documentación y exposición | 2 |
| Total de la tabla | 13 |

El enunciado dice que el proyecto vale 12 puntos, pero los cinco valores de la rúbrica suman 13. Dejar esta discrepancia anotada para confirmarla con el docente.

## Pendientes para cerrar el proyecto

- Revisar las conexiones guardadas desde pgAdmin y guardar capturas de evidencia.
- Completar integrantes, docente y fecha de entrega.
- Confirmar con el docente si el puntaje total es 12 o 13.
- Entregar la URL del repositorio privado al equipo e invitar a sus integrantes si trabajarán directamente en GitHub.
