# Replicación bidireccional para una cadena de farmacias

Proyecto universitario de Infraestructura de TI: demostración académica de dos nodos PostgreSQL activos que intercambian cambios mediante replicación lógica.

## Escenario y alcance

Una farmacia con dos sucursales registra ventas e inventario en su propio nodo. Los cambios se replican para que ambos nodos mantengan una copia de la información compartida. El esquema incluye sucursales, medicamentos, inventario, ventas y detalle de ventas.

El equipo ya tiene PostgreSQL 18.6 instalado. El proyecto usa esa instalación para crear dos clústeres de datos independientes en los puertos 5433 y 5434. Los archivos de datos quedan en `%LOCALAPPDATA%\FarmaciaReplicacion`; la instancia existente en 5432 y `BOLETA_VENTAS` no se modifican.

## Inicio rápido

Abre PowerShell en esta carpeta y ejecuta:

```powershell
.\scripts\iniciar.ps1
```

En la primera ejecución, se crea `.env` desde `.env.example`; revisa la ruta `PG_BIN` si PostgreSQL está instalado en otro directorio. Después registra los nodos en pgAdmin:

| Campo | Nodo A | Nodo B |
|---|---|---|
| Host | `127.0.0.1` | `127.0.0.1` |
| Puerto | `5433` | `5434` |
| Base | `farmacia` | `farmacia` |
| Usuario | `farmacia_admin` | `farmacia_admin` |

Las contraseñas de ejemplo están en `.env` local. La guía con demostración, diagnóstico y detención está en [`docs/instalacion.md`](docs/instalacion.md). Diagrama: [`docs/arquitectura.svg`](docs/arquitectura.svg).

## Estructura

- `database/`: esquema, publicaciones y datos de demostración/conflicto.
- `scripts/`: inicio, detención, verificación y medición.
- `docs/`: arquitectura, instalación, pruebas y resolución de conflictos.
- `informe/`: informe técnico editable en DOCX y PDF, con fuente Markdown y resultados CSV.
- `presentacion/`: presentación editable PPTX y guion de exposición oral.

## Estado

Los dos clústeres se iniciaron y se probaron la replicación en ambos sentidos, las escrituras concurrentes, la interrupción temporal, la recuperación de un conflicto y una medición básica. Los resultados están asentados en el informe y el plan de pruebas. Falta completar los datos del grupo y guardar capturas desde pgAdmin; ver [`docs/seguimiento_entregables.md`](docs/seguimiento_entregables.md).

Este proyecto está en su propia carpeta y repositorio, separado de `GYM_CONTROL`. Es una demostración académica local con datos ficticios, no una configuración de producción.
