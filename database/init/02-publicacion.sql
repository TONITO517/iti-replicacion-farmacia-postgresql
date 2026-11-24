GRANT USAGE ON SCHEMA public TO replicador;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO replicador;

CREATE PUBLICATION pub_farmacia
    FOR TABLE sucursal, medicamento, inventario, venta, detalle_venta;
