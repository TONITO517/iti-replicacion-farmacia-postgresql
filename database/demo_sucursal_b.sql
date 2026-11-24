BEGIN;

WITH nueva_venta AS (
    INSERT INTO venta (sucursal_id, total, observacion)
    VALUES (2, 17.80, 'Venta de demostración en Sucursal B')
    RETURNING venta_id
)
INSERT INTO detalle_venta (venta_id, numero_linea, medicamento_id, cantidad, precio_unitario)
SELECT venta_id, 1, '10000000-0000-4000-8000-000000000002', 2, 8.90
FROM nueva_venta;

UPDATE inventario
SET unidades = unidades - 2, actualizado_en = now()
WHERE sucursal_id = 2
  AND medicamento_id = '10000000-0000-4000-8000-000000000002'
  AND unidades >= 2;

COMMIT;
