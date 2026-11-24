param(
    [ValidateRange(10, 1000)]
    [int]$Cantidad = 100,
    [ValidateRange(5, 120)]
    [int]$EsperaMaximaSegundos = 30
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\common.ps1"
$projectRoot = Split-Path -Parent $PSScriptRoot
$config = Import-FarmaciaConfig -ProjectRoot $projectRoot
$runId = [guid]::NewGuid().ToString('N')
$prefix = "CARGA-$runId-"
$insertSql = "INSERT INTO venta (sucursal_id, total, observacion) SELECT 1, 1.00, '$prefix' || g FROM generate_series(1, $Cantidad) AS g;"

Write-Host "Insertando $Cantidad ventas de medición en Nodo A..."
$timer = [System.Diagnostics.Stopwatch]::StartNew()
Invoke-FarmaciaPsql -Settings $config -Port 5433 -Database $config['POSTGRES_DB'] -Sql $insertSql | Out-Null
$timer.Stop()
$insertMs = [math]::Round($timer.Elapsed.TotalMilliseconds, 2)

$countSql = "SELECT count(*) FROM venta WHERE observacion LIKE '$prefix%';"
$deadline = [DateTimeOffset]::UtcNow.AddSeconds($EsperaMaximaSegundos)
$observed = 0
$replicationTimer = [System.Diagnostics.Stopwatch]::StartNew()
while ([DateTimeOffset]::UtcNow -lt $deadline) {
    $count = (Invoke-FarmaciaPsql -Settings $config -Port 5434 -Database $config['POSTGRES_DB'] -Sql $countSql -TuplesOnly | Out-String).Trim()
    $observed = [int]$count
    if ($observed -ge $Cantidad) { break }
    Start-Sleep -Milliseconds 200
}
$replicationTimer.Stop()

$converged = $observed -ge $Cantidad
$result = [pscustomobject]@{
    fecha_utc = [DateTimeOffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
    filas_insertadas = $Cantidad
    tiempo_insercion_local_ms = $insertMs
    filas_observadas_en_nodo_b = $observed
    convergio = $converged
    tiempo_hasta_convergencia_observada_ms = if ($converged) { [math]::Round($replicationTimer.Elapsed.TotalMilliseconds, 2) } else { $null }
    identificador_prueba = $runId
}

$csvPath = Join-Path $projectRoot 'informe\resultados_rendimiento.csv'
if (Test-Path -LiteralPath $csvPath) {
    $result | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Append -Encoding utf8
} else {
    $result | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding utf8
}
$result | Format-List
if (-not $converged) { throw "No se observaron las $Cantidad filas en $EsperaMaximaSegundos segundos; revisa las suscripciones y los logs." }
Write-Host "Medición guardada en $csvPath"
Write-Host 'La convergencia observada incluye el intervalo de sondeo y el inicio de psql; no es una medición pura de latencia de red.'
