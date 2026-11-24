# Instalación y uso local

## Requisitos

- Windows 10/11 de 64 bits.
- Docker Desktop con el motor Linux iniciado.
- pgAdmin 4 para administrar y consultar las dos instancias.
- Conexión a Internet la primera vez para descargar la imagen `postgres:16`.

El PostgreSQL 18 instalado en Windows no se modifica. El proyecto levanta dos contenedores PostgreSQL 16 aislados en los puertos 5433 y 5434.

## Inicio

1. Abrir Docker Desktop y esperar a que el motor indique que está activo.
2. Abrir PowerShell en la carpeta `FARMACIA-REPLICACION`.
3. Ejecutar:

   ```powershell
   .\scripts\iniciar.ps1
   ```

La primera ejecución crea el archivo local `.env`, descarga la imagen y arranca los dos nodos. La configuración de suscripciones se ejecuta después de que ambos servidores respondan.

## Registrar los nodos en pgAdmin

Registrar dos servidores con los siguientes datos. El nombre del servidor en pgAdmin es una etiqueta libre.

| Campo | Nodo A | Nodo B |
|---|---|---|
| Nombre | Farmacia - Nodo A | Farmacia - Nodo B |
| Host | `127.0.0.1` | `127.0.0.1` |
| Puerto | `5433` | `5434` |
| Base de datos de mantenimiento | `farmacia` | `farmacia` |
| Usuario | Valor `POSTGRES_USER` de `.env` | Valor `POSTGRES_USER` de `.env` |
| Contraseña | Valor `POSTGRES_PASSWORD` de `.env` | Valor `POSTGRES_PASSWORD` de `.env` |

No se debe conectar el proyecto a `BOLETA_VENTAS`; esa es una base aparte del servidor instalado en Windows.

## Demostración de ida y vuelta

1. En pgAdmin, seleccionar `Farmacia - Nodo A`, abrir Query Tool y ejecutar el archivo `database/demo_sucursal_a.sql`.
2. Esperar unos segundos y en el Nodo B consultar:

   ```sql
   SELECT v.venta_id, s.nombre, v.total
   FROM venta AS v
   JOIN sucursal AS s USING (sucursal_id)
   ORDER BY v.registrada_en;
   ```

3. Repetir desde `database/demo_sucursal_b.sql` en Nodo B y confirmar que la venta aparece en Nodo A.
4. Comparar el inventario por sucursal en ambos nodos:

   ```sql
   SELECT s.nombre, m.nombre AS medicamento, i.unidades
   FROM inventario AS i
   JOIN sucursal AS s USING (sucursal_id)
   JOIN medicamento AS m USING (medicamento_id)
   ORDER BY s.sucursal_id, m.codigo;
   ```

5. Para revisar el estado de las suscripciones, ejecutar `scripts/verificar.ps1`.

## Detener y conservar datos

```powershell
.\scripts\detener.ps1
```

Este comando detiene y elimina los contenedores, pero conserva los volúmenes de datos para el próximo inicio.

## Diagnóstico básico

- `docker ps`: confirmar que los contenedores están activos.
- `docker compose logs nodo-a nodo-b`: consultar mensajes de PostgreSQL.
- `docker compose logs configurar-replicacion`: revisar el arranque de las suscripciones.
- `docker compose exec nodo-a psql -U farmacia_admin -d farmacia -c "SELECT * FROM pg_stat_subscription;"`: ver actividad de replicación.
- Si aparece un error de contraseña o una réplica detenida, conservar el mensaje completo y revisar el apartado de conflictos antes de reiniciar o borrar volúmenes.

Las contraseñas del `.env` de ejemplo son únicamente para la demo local. No usar estos valores en un servidor expuesto a Internet.
