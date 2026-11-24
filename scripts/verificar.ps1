$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\common.ps1"
$projectRoot = Split-Path -Parent $PSScriptRoot
$config = Import-FarmaciaConfig -ProjectRoot $projectRoot

foreach ($node in @(@{ Name = 'nodo-a'; Port = 5433 }, @{ Name = 'nodo-b'; Port = 5434 })) {
    Write-Host "`n== $($node.Name): suscripciones =="
    Invoke-FarmaciaPsql -Settings $config -Port $node.Port -Database $config['POSTGRES_DB'] -Sql 'SELECT subname, subenabled FROM pg_subscription ORDER BY subname;'
    Write-Host "== $($node.Name): ventas =="
    Invoke-FarmaciaPsql -Settings $config -Port $node.Port -Database $config['POSTGRES_DB'] -Sql "SELECT v.venta_id, s.nombre AS sucursal, v.registrada_en, v.total FROM venta v JOIN sucursal s USING (sucursal_id) ORDER BY v.registrada_en;"
    Write-Host "== $($node.Name): inventario =="
    Invoke-FarmaciaPsql -Settings $config -Port $node.Port -Database $config['POSTGRES_DB'] -Sql "SELECT s.nombre, m.nombre AS medicamento, i.unidades FROM inventario i JOIN sucursal s USING (sucursal_id) JOIN medicamento m USING (medicamento_id) ORDER BY s.sucursal_id, m.codigo;"
}
