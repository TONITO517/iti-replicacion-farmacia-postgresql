# Replicación bidireccional para una cadena de farmacias

Proyecto universitario de Infraestructura de TI: demostración académica de dos nodos PostgreSQL activos que intercambian cambios mediante replicación lógica.

## Escenario

Una farmacia con dos sucursales registra ventas y movimientos de inventario en su propio nodo. Los datos de ambas sedes se replican para que cada nodo mantenga una copia de la información compartida.

## Alcance

- Dos instancias PostgreSQL aisladas y administrables con pgAdmin.
- Replicación lógica bidireccional entre ambos nodos.
- Esquema de demostración para sucursales, medicamentos, inventario y ventas.
- Regla de operación para reducir conflictos: cada sucursal modifica el inventario que le pertenece y cada venta usa un identificador único.
- Guía de instalación, demostración y diagnóstico.
- Informe técnico y material de exposición, como entregables separados del código.

El proyecto se desarrollará en esta carpeta y en su propio repositorio. No forma parte de `GYM_CONTROL`.

## Estado

En preparación. Se validó el archivo de Compose con `docker compose config --quiet`. Docker Desktop está instalado, pero el motor devolvió un error de API en el último intento; por eso todavía no se ha probado la ejecución de los nodos ni la replicación real.

## Estructura prevista

```text
database/       Esquema y datos demostrativos
scripts/        Inicio, configuración y verificación de los nodos
docs/           Arquitectura, instalación y guía de exposición
informe/        Informe técnico del proyecto
presentacion/   Material de exposición
```

## Inicio rápido

Con Docker Desktop abierto y el motor Linux activo, ejecutar en PowerShell:

```powershell
.\scripts\iniciar.ps1
```

Luego registrar en pgAdmin `127.0.0.1:5433` (Nodo A) y `127.0.0.1:5434` (Nodo B). Las instrucciones completas, incluida la demostración en ambos sentidos, están en [`docs/instalacion.md`](docs/instalacion.md).

## Pruebas

El plan incluye replicación en ambos sentidos, integridad, interrupción temporal y un conflicto único controlado con recuperación. Los resultados que requieren ejecutar Docker siguen pendientes; ver [`docs/plan_pruebas.md`](docs/plan_pruebas.md).

## Importante

Esta es una demostración local para fines académicos. La topología activa-activa necesita reglas de escritura para evitar que dos sucursales cambien simultáneamente la misma fila. La replicación lógica nativa también puede detenerse si un cambio entrante viola una restricción; el informe describirá esta limitación y el procedimiento de resolución elegido.
