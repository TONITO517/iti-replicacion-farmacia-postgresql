# Seguimiento del enunciado

| Requisito | Trabajo preparado | Estado verificable |
|---|---|---|
| 1. Selección de tecnología | Justificación de PostgreSQL frente a los criterios de replicación, rendimiento, escalabilidad y facilidad de uso en `informe/informe_tecnico.md` | Redactado; el informe todavía necesita completar nombres del grupo y resultados. |
| 2. Diseño de arquitectura | Dos nodos activos, publicación/suscripción, sincronización asíncrona, reglas de conflicto y seguridad en `docs/arquitectura.md` y el informe | Diseñado; pendiente incorporar el diagrama final que usará el grupo. |
| 3. Implementación | Docker Compose, esquema SQL, ejemplos de ventas, inicio, detención y configuración de suscripciones | Archivos preparados; la configuración real todavía no se ha podido ejecutar porque el motor Docker devolvió un error de API. |
| 4. Evaluación y pruebas | Pruebas de ida y vuelta, integridad, interrupción, conflicto/recuperación y medición básica | Plan y scripts preparados; resultados pendientes de ejecución y evidencia. |
| 5. Informe técnico | Borrador con problema, elección, arquitectura, implementación, pruebas, conclusiones y recomendaciones | Borrador en Markdown; la copia DOCX se generó localmente pero no se incorpora al repositorio hasta contar con renderizado visual satisfactorio. |
| Código fuente | SQL y scripts del proyecto | Preparado en esta carpeta, independiente de `GYM_CONTROL`. |
| Presentación oral | Guion de siete diapositivas con lo que se debe explicar | Preparado; se agregará evidencia de la demostración después de ejecutar las pruebas. |

## Pendientes para cerrar el proyecto

- Resolver el arranque del motor Docker y probar ambos nodos en tiempo de ejecución.
- Revisar credenciales y conexiones desde pgAdmin.
- Ejecutar P01-P09, guardar capturas y registrar datos reales de rendimiento.
- Completar autores, docente y fecha del informe.
- Renderizar y revisar visualmente la versión final DOCX; actualizar la exposición con los resultados observados.
- Confirmar la visibilidad del repositorio GitHub y publicarlo en el perfil autorizado.
