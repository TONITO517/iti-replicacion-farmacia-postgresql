param(
    [ValidateRange(10, 1000)]
    [int]$Cantidad = 100,
    [ValidateRange(5, 120)]
    [int]$EsperaMaximaSegundos = 30
)

$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)

$runId = [guid]::NewGuid().ToString('N')
$prefijo = "CARGA-$runId-"
$insertSql = "INSERT INTO venta (sucursal_id, total, observacion) SELECT 1, 1.00, '$prefijo' || g FROM generate_series(1, $Cantidad) AS g;"

Write-Host "Insertando $Cantidad ventas de medición en Nodo A..."
$timer = [System.Diagnostics.Stopwatch]::StartNew()
docker compose exec -T nodo-a psql -X -q -U farmacia_admin -d farmacia -v ON_ERROR_STOP=1 -c $insertSql | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Falló la inserción de medición en Nodo A.' }
$timer.Stop()
$insertMs = [math]::Round($timer.Elapsed.TotalMilliseconds, 2)

$countSql = "SELECT count(*) FROM venta WHERE observacion LIKE '$prefijo%';"
$limit = [DateTimeOffset]::UtcNow.AddSeconds($EsperaMaximaSegundos)
$observed = 0
$replicationTimer = [System.Diagnostics.Stopwatch]::StartNew()

while ([DateTimeOffset]::UtcNow -lt $limit) {
    $countOutput = docker compose exec -T nodo-b psql -X -q -t -A -U farmacia_admin -d farmacia -v ON_ERROR_STOP=1 -c $countSql
    if ($LASTEXITCODE -ne 0) { throw 'Falló la consulta de convergencia en Nodo B.' }
    $observed = [int](($countOutput | Out-String).Trim())
    if ($observed -ge $Cantidad) { break }
    Start-Sleep -Milliseconds 200
}

$replicationTimer.Stop()
$converged = $observed -ge $Cantidad
$replicationMs = if ($converged) { [math]::Round($replicationTimer.Elapsed.TotalMilliseconds, 2) } else { $null }

$result = [pscustomobject]@{
    fecha_utc = [DateTimeOffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
    nodo_origen = 'A'
    nodo_destino = 'B'
    filas_insertadas = $Cantidad
    tiempo_insercion_local_ms = $insertMs
    filas_observadas_en_destino = $observed
    convergio = $converged
    tiempo_hasta_convergencia_observada_ms = $replicationMs
    identificador_prueba = $runId
}

$csvPath = Join-Path $PSScriptRoot '..\informe\resultados_rendimiento.csv'
if (Test-Path -LiteralPath $csvPath) {
    $result | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Append -Encoding utf8
} else {
    $result | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding utf8
}

$result | Format-List
if (-not $converged) {
    throw "No se observaron las $Cantidad filas en Nodo B dentro de $EsperaMaximaSegundos segundos. Revisa las suscripciones y los logs."
}

Write-Host "Medición guardada en $csvPath"
Write-Host 'La convergencia observada incluye el intervalo de sondeo; no es una medición de latencia de red pura.'
