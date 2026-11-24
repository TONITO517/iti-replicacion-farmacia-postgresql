# Instalación y uso local

## Requisitos

- Windows 10/11 de 64 bits.
- PostgreSQL 18 instalado; se usarán sus herramientas (`initdb`, `pg_ctl` y `psql`).
- pgAdmin 4 para administrar y consultar las dos instancias.

El proyecto crea dos clústeres PostgreSQL 18 separados bajo `%LOCALAPPDATA%\FarmaciaReplicacion`, en los puertos 5433 y 5434. La instancia que ya usa el puerto 5432 y la base `BOLETA_VENTAS` no se modifican. No se necesita Docker.

## Inicio

1. Abrir PowerShell en la carpeta `FARMACIA-REPLICACION`.
2. Revisar `PG_BIN` en `.env.example`; si PostgreSQL 18 está en la ruta estándar, el script la detectará al crear `.env`.
3. Ejecutar:

   ```powershell
   .\scripts\iniciar.ps1
   ```

La primera ejecución crea `.env`, inicializa los dos clústeres y configura las suscripciones. Las carpetas de datos quedan fuera del repositorio.

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
6. Para realizar una medición sencilla con 100 ventas ficticias, ejecutar `scripts/medir-replicacion.ps1`. Se puede cambiar la cantidad con `-Cantidad 250`; los resultados se guardan en `informe/resultados_rendimiento.csv`.

## Detener y conservar datos

```powershell
.\scripts\detener.ps1
```

Este comando detiene los dos servidores, pero conserva sus carpetas de datos para el próximo inicio.

## Diagnóstico básico

- Consultar `%LOCALAPPDATA%\FarmaciaReplicacion\nodo-a\server.log` y `nodo-b\server.log` para revisar los registros.
- En pgAdmin, consultar `SELECT * FROM pg_stat_subscription;` en cada nodo.
- Si aparece un error de contraseña o una réplica detenida, conservar el mensaje completo y revisar el apartado de conflictos antes de reiniciar o borrar volúmenes.

La medición registra el tiempo del comando de inserción local y cuánto tardó el sondeo en observar todas las filas en el destino. Incluye la invocación de `psql` y el intervalo de sondeo, así que sirve como comparación de la demo, no como benchmark de red ni como cifra de producción.

Las contraseñas del `.env` de ejemplo son únicamente para la demo local. No usar estos valores en un servidor expuesto a Internet.
