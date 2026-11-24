$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)

foreach ($node in @('nodo-a', 'nodo-b')) {
    Write-Host "`n== ${node}: estado de suscripciones =="
    docker compose exec -T $node psql -U farmacia_admin -d farmacia -c "SELECT subname, subenabled FROM pg_subscription;"
    if ($LASTEXITCODE -ne 0) { throw "No se pudo consultar $node." }

    Write-Host "== ${node}: ventas replicadas =="
    docker compose exec -T $node psql -U farmacia_admin -d farmacia -c "SELECT v.venta_id, s.nombre AS sucursal, v.registrada_en, v.total FROM venta v JOIN sucursal s USING (sucursal_id) ORDER BY v.registrada_en;"
    if ($LASTEXITCODE -ne 0) { throw "No se pudieron consultar las ventas de $node." }
}
