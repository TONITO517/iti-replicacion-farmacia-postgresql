-- Ejecutar en el Nodo A al terminar las pruebas; los DELETE se replican al Nodo B.
DELETE FROM medicamento
WHERE medicamento_id IN (
    '20000000-0000-4000-8000-000000000001',
    '20000000-0000-4000-8000-000000000002'
);

DELETE FROM venta
WHERE observacion LIKE 'CARGA-%'
   OR observacion LIKE 'P05-%'
   OR observacion = 'Prueba interrupcion temporal';
