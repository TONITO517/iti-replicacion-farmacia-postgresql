# Trabajo de Fin de Semestre: Replicación de Base de Datos

## Sistema de replicación para una cadena de farmacias

**Curso:** Infraestructura de Tecnología de Información  
**Escuela Profesional:** Ingeniería de Sistemas  
**Integrantes:** Pendiente  
**Docente:** Pendiente  
**Fecha:** Pendiente

> Borrador de trabajo. Los resultados de pruebas se completarán con evidencia después de ejecutar la solución. No se deben presentar resultados pendientes como si ya hubieran sido medidos.

## Resumen

Este proyecto propone y desarrolla una demostración académica de replicación bidireccional lógica entre dos instancias PostgreSQL. El caso de uso es una cadena de farmacias con dos sucursales que registran ventas y movimientos de inventario de forma local. Cada instancia publica sus cambios y recibe los cambios de la otra. Docker Compose permite iniciar los nodos de forma aislada en una computadora, y pgAdmin permite administrarlos y observar los datos.

La solución prioriza una instalación reproducible y comprensible para un proyecto universitario. Para reducir conflictos, las ventas usan UUID y cada sucursal modifica el inventario que le pertenece. La replicación es asíncrona: el cambio se confirma primero en el nodo local y luego llega al otro. PostgreSQL puede detener la aplicación de una transacción ante ciertos conflictos; el diseño incluye una regla de prevención y un procedimiento manual de diagnóstico y recuperación.

## 1. Descripción del problema

Una cadena con más de una farmacia necesita consultar ventas e inventario de cada sede. Si toda la operación depende de una única base central, una interrupción de red puede impedir que una sede registre sus transacciones. Una copia local por sede permite continuar el registro local y sincronizar los cambios cuando se recupere la conexión.

El problema técnico consiste en mantener dos bases con estructuras compatibles y propagar las inserciones, actualizaciones y eliminaciones entre ellas, conservando la integridad de ventas, detalle de venta, medicamentos y existencias. También se debe explicar qué sucede cuando ambos nodos modifican datos incompatibles.

## 2. Objetivos

### Objetivo general

Diseñar e implementar una demostración de replicación bidireccional entre dos nodos PostgreSQL para ilustrar disponibilidad, sincronización de datos y manejo de conflictos en un caso de farmacia.

### Objetivos específicos

- Justificar la elección de PostgreSQL con criterios de replicación, rendimiento, escalabilidad y facilidad de uso.
- Diseñar una arquitectura activa-activa de dos nodos con publicación y suscripción en ambas direcciones.
- Crear el esquema de sucursales, medicamentos, inventario, ventas y detalle de ventas.
- Configurar y administrar los nodos con Docker Compose y pgAdmin.
- Comprobar replicación en ambos sentidos, interrupción temporal y manejo de un conflicto controlado.

## 3. Selección de tecnología

Se selecciona **PostgreSQL** como gestor de base de datos y **pgAdmin 4** como herramienta de administración. La elección cumple el requisito del enunciado, que permite PostgreSQL y excluye MySQL/MariaDB.

| Criterio | Justificación para este proyecto |
|---|---|
| Replicación | PostgreSQL incluye replicación lógica mediante publicaciones y suscripciones. Un nodo puede publicar tablas y también suscribirse a las publicaciones de otro nodo. Desde PostgreSQL 16, la opción `origin = 'none'` permite solicitar únicamente cambios sin origen de replicación, lo que ayuda a prevenir ciclos entre nodos. |
| Rendimiento | La replicación lógica transmite cambios confirmados a nivel de filas, no copias completas de cada archivo de datos. Esto permite replicar las tablas necesarias y observar el comportamiento con ventas e inventario. El rendimiento real de esta demo se medirá; no se atribuyen cifras sin una prueba reproducible. |
| Escalabilidad | Se pueden añadir suscriptores y extender la topología. Sin embargo, la solución de dos nodos no es un clúster de consenso y el costo de coordinación/conflictos aumenta cuando varias sedes modifican las mismas filas. |
| Facilidad de uso | pgAdmin proporciona una interfaz gráfica para consultar tablas, ejecutar SQL y revisar conexiones. Docker Compose facilita iniciar las dos instancias con puertos y datos separados sin cambiar la instalación PostgreSQL 18 existente en Windows. |
| Costo y disponibilidad | PostgreSQL es software de código abierto con documentación oficial pública; Docker Desktop y pgAdmin ya están disponibles en el equipo usado para la demostración. |

Se utiliza la imagen mayor `postgres:16` en los contenedores porque ambas instancias deben tener la misma configuración y esa versión incorpora el filtrado de cambios por origen usado por el diseño. PostgreSQL 16 permanece dentro de su periodo oficial de soporte según la política de versiones consultada. La instalación PostgreSQL 18.6 del equipo no se altera.

### Alcance de la elección

El proyecto implementa replicación lógica nativa en dos direcciones y demuestra reglas de operación que reducen conflictos. No busca reemplazar plataformas de replicación distribuida con resolución automática avanzada, ni afirma que la replicación lógica nativa sea una solución de alta disponibilidad empresarial sin intervención.

## 4. Diseño de la arquitectura

### 4.1 Topología

Cada sucursal se conecta a su propio nodo PostgreSQL. Ambos nodos publican los cambios de las tablas del sistema y se suscriben a la publicación del otro. pgAdmin se conecta como cliente de administración a cada puerto.

```mermaid
flowchart LR
  subgraph A[Farmacia - Sucursal A]
    UA[Personal de sucursal]
    NA[(Nodo A - PostgreSQL 16)]
    UA --> NA
  end
  subgraph B[Farmacia - Sucursal B]
    UB[Personal de sucursal]
    NB[(Nodo B - PostgreSQL 16)]
    UB --> NB
  end
  NA <-->|Publicación / suscripción\nReplicación lógica bidireccional| NB
  PA[pgAdmin 4] -. administración .-> NA
  PA -. administración .-> NB
```

### 4.2 Componentes

- **Nodo A:** contenedor PostgreSQL, puerto local `5433`, volumen `nodo_a_datos`.
- **Nodo B:** contenedor PostgreSQL, puerto local `5434`, volumen `nodo_b_datos`.
- **Docker Compose:** crea la red privada entre contenedores y mantiene sus datos separados.
- **pgAdmin 4:** cliente visual para consultar ambos nodos; no realiza la replicación.
- **Usuario `replicador`:** rol dedicado con permiso de replicación y lectura de tablas publicadas.
- **Base `farmacia`:** catálogo y operaciones simuladas para dos sucursales.

Los puertos se enlazan a `127.0.0.1`, por lo que esta configuración está pensada para una demo en la computadora local, no para exponer los servidores en Internet.

### 4.3 Mecanismo de sincronización

Cada nodo crea una publicación de las tablas `sucursal`, `medicamento`, `inventario`, `venta` y `detalle_venta`. En cada nodo se define una suscripción a la publicación del nodo opuesto. Ambas instancias arrancan con el mismo esquema y datos base; la suscripción se crea con `copy_data = false` para no volver a insertar ese catálogo inicial y generar colisiones de claves.

La opción `origin = 'none'` evita reenviar como nuevos los cambios que el nodo recibió por replicación. La sincronización es asíncrona: una transacción aparece primero en su nodo de origen y llega después al otro.

### 4.4 Estrategia para reducir y resolver conflictos

La regla normal de escritura asigna a cada sucursal la propiedad de sus filas de inventario. Sucursal A actualiza filas con `sucursal_id = 1`; Sucursal B actualiza filas con `sucursal_id = 2`. Las ventas usan UUID para reducir la posibilidad de claves duplicadas. El catálogo se modifica de forma centralizada durante la demostración, evitando edición concurrente de la misma fila.

Estas reglas reducen conflictos de negocio, pero no imponen por sí solas permisos por sucursal. Un cambio simultáneo a una misma fila puede causar que la aplicación lógica reporte un conflicto y se detenga hasta corregir los datos. El procedimiento propuesto es revisar el log y las estadísticas, identificar la clave afectada, aplicar una decisión explícita y comprobar que la suscripción continúa. No se omiten transacciones a ciegas porque eso podría perder cambios relacionados.

### 4.5 Seguridad

- Las conexiones de los contenedores se exponen solo a `localhost`.
- La replicación usa un rol diferente del usuario administrador.
- Las contraseñas de ejecución se guardan en `.env`, archivo excluido de Git; se publica solo `.env.example` con valores de demostración.
- No se usan datos reales de pacientes, recetas ni clientes.
- Las credenciales de ejemplo solo sirven para el entorno educativo local y deben cambiarse antes de cualquier despliegue compartido.

## 5. Implementación

La implementación se organiza en `docker-compose.yml`, scripts PowerShell de inicio/verificación, scripts SQL de esquema y demostración, y un script de configuración de suscripciones. El servidor PostgreSQL que ya existe en Windows se mantiene independiente. pgAdmin se conecta a `127.0.0.1:5433` y `127.0.0.1:5434`.

El esquema incluye sucursales, medicamentos, inventario por sucursal, ventas y líneas de venta. Las claves primarias y foráneas mantienen la relación entre las operaciones. Las consultas de ejemplo muestran una venta creada en cada nodo y el inventario correspondiente.

### Estado de ejecución

Los archivos de configuración están preparados y `docker compose config --quiet` validó la sintaxis de Compose. La prueba de integración sigue pendiente de que Docker Desktop responda al motor de contenedores; no se afirma todavía que los nodos se hayan iniciado ni que los datos se hayan replicado.

## 6. Evaluación y pruebas

El plan completo está en `docs/plan_pruebas.md`. Incluye el estado inicial, replicación Nodo A→B, replicación Nodo B→A, integridad referencial, escrituras simultáneas en filas distintas, interrupción temporal y un conflicto controlado con su recuperación.

### Resultados

| Prueba | Resultado | Evidencia |
|---|---|---|
| Validación de sintaxis de Docker Compose | Aprobada | `docker compose config --quiet` terminó con código 0. |
| Replicación en ambos sentidos | Pendiente | Requiere iniciar el motor Docker y ejecutar las consultas de demostración. |
| Consistencia e integridad | Pendiente | Requiere ejecutar las consultas en ambos nodos. |
| Tolerancia a una interrupción temporal | Pendiente | Requiere detener y reanudar un contenedor durante una práctica controlada. |
| Conflicto y recuperación | Pendiente | Requiere prueba controlada con datos descartables. |
| Rendimiento | Pendiente | No se publicarán cifras hasta medirlas con una carga y entorno documentados. |

## 7. Limitaciones

- La replicación es asíncrona y puede tener retraso.
- La configuración no incluye consenso, balanceador, descubrimiento automático de nodo activo ni failover transparente.
- La topología tiene dos nodos locales dentro de un equipo; no reproduce la latencia ni las fallas de dos sedes físicas.
- Los conflictos que violan restricciones pueden detener el worker y necesitar intervención manual.
- El modelo de farmacias es didáctico, no administra recetas, datos clínicos ni información de clientes reales.

## 8. Conclusiones y recomendaciones

PostgreSQL permite construir una demostración entendible de replicación lógica bidireccional con dos nodos, y pgAdmin facilita inspeccionar el resultado. Separar el inventario por sucursal y usar UUID en las ventas ayuda a que las escrituras normales de ambas sedes no compitan por las mismas claves.

La replicación no elimina la necesidad de reglas de negocio. Para un entorno real se recomendaría evaluar requisitos de consistencia, resolución de conflictos, operación de sedes y recuperación ante desastres con una solución distribuida soportada, controles de seguridad más estrictos, monitoreo y copias de seguridad verificadas.

## Referencias

- PostgreSQL Global Development Group. *Logical Replication*. https://www.postgresql.org/docs/16/logical-replication.html
- PostgreSQL Global Development Group. *CREATE SUBSCRIPTION*, opción `origin`. https://www.postgresql.org/docs/16/sql-createsubscription.html
- PostgreSQL Global Development Group. *Conflicts*. https://www.postgresql.org/docs/16/logical-replication-conflicts.html
- PostgreSQL Global Development Group. *Versioning Policy*. https://www.postgresql.org/support/versioning/
- Docker. *Compose file reference*. https://docs.docker.com/reference/compose-file/
- pgAdmin Development Team. *pgAdmin 4 Documentation*. https://www.pgadmin.org/docs/pgadmin4/latest/
- Enunciado del Trabajo de Fin de Semestre: Replicación de Base de Datos, curso de Infraestructura de Tecnología de Información.
