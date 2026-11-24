CREATE TABLE sucursal (
    sucursal_id smallint PRIMARY KEY,
    nombre text NOT NULL UNIQUE,
    ciudad text NOT NULL
);

CREATE TABLE medicamento (
    medicamento_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    codigo text NOT NULL UNIQUE,
    nombre text NOT NULL,
    principio_activo text NOT NULL,
    precio_venta numeric(10, 2) NOT NULL CHECK (precio_venta > 0),
    requiere_receta boolean NOT NULL DEFAULT false
);

CREATE TABLE inventario (
    sucursal_id smallint NOT NULL REFERENCES sucursal(sucursal_id),
    medicamento_id uuid NOT NULL REFERENCES medicamento(medicamento_id),
    unidades integer NOT NULL CHECK (unidades >= 0),
    actualizado_en timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (sucursal_id, medicamento_id)
);

CREATE TABLE venta (
    venta_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    sucursal_id smallint NOT NULL REFERENCES sucursal(sucursal_id),
    registrada_en timestamptz NOT NULL DEFAULT now(),
    total numeric(12, 2) NOT NULL CHECK (total >= 0),
    observacion text
);

CREATE TABLE detalle_venta (
    venta_id uuid NOT NULL REFERENCES venta(venta_id) ON DELETE CASCADE,
    numero_linea smallint NOT NULL,
    medicamento_id uuid NOT NULL REFERENCES medicamento(medicamento_id),
    cantidad integer NOT NULL CHECK (cantidad > 0),
    precio_unitario numeric(10, 2) NOT NULL CHECK (precio_unitario > 0),
    PRIMARY KEY (venta_id, numero_linea)
);

INSERT INTO sucursal (sucursal_id, nombre, ciudad) VALUES
    (1, 'Farmacia Centro', 'Lima'),
    (2, 'Farmacia Norte', 'Lima');

INSERT INTO medicamento (medicamento_id, codigo, nombre, principio_activo, precio_venta, requiere_receta) VALUES
    ('10000000-0000-4000-8000-000000000001', 'MED-001', 'Paracetamol 500 mg', 'Paracetamol', 4.50, false),
    ('10000000-0000-4000-8000-000000000002', 'MED-002', 'Loratadina 10 mg', 'Loratadina', 8.90, false),
    ('10000000-0000-4000-8000-000000000003', 'MED-003', 'Amoxicilina 500 mg', 'Amoxicilina', 18.00, true);

INSERT INTO inventario (sucursal_id, medicamento_id, unidades) VALUES
    (1, '10000000-0000-4000-8000-000000000001', 80),
    (1, '10000000-0000-4000-8000-000000000002', 35),
    (1, '10000000-0000-4000-8000-000000000003', 24),
    (2, '10000000-0000-4000-8000-000000000001', 55),
    (2, '10000000-0000-4000-8000-000000000002', 42),
    (2, '10000000-0000-4000-8000-000000000003', 16);
