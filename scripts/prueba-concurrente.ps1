$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\common.ps1"
$projectRoot = Split-Path -Parent $PSScriptRoot
$config = Import-FarmaciaConfig -ProjectRoot $projectRoot
$psql = Join-Path $config['PG_BIN'] 'psql.exe'
$runId = [guid]::NewGuid().ToString('N')
$marker = "P05-$runId"
$saleA = [guid]::NewGuid().ToString()
$saleB = [guid]::NewGuid().ToString()

function Start-ConcurrentInsert {
    param([int]$Port, [string]$SaleId, [int]$BranchId)
    $startInfo = [System.Diagnostics.ProcessStartInfo]::new($psql)
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    foreach ($argument in @('-X','-v','ON_ERROR_STOP=1','-h','127.0.0.1','-p',[string]$Port,'-U',$config['POSTGRES_USER'],'-d',$config['POSTGRES_DB'])) {
        $startInfo.ArgumentList.Add($argument)
    }
    $sql = "INSERT INTO venta (venta_id,sucursal_id,total,observacion) VALUES ('$SaleId',$BranchId,1.00,'$marker');"
    $startInfo.ArgumentList.Add('-c')
    $startInfo.ArgumentList.Add($sql)
    $startInfo.Environment['PGPASSWORD'] = $config['POSTGRES_PASSWORD']
    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    if (-not $process.Start()) { throw "No se pudo iniciar psql para el puerto $Port." }
    return $process
}

$processA = Start-ConcurrentInsert -Port 5433 -SaleId $saleA -BranchId 1
$processB = Start-ConcurrentInsert -Port 5434 -SaleId $saleB -BranchId 2
$processA.WaitForExit()
$processB.WaitForExit()
$outputA = $processA.StandardOutput.ReadToEnd()
$errorA = $processA.StandardError.ReadToEnd()
$outputB = $processB.StandardOutput.ReadToEnd()
$errorB = $processB.StandardError.ReadToEnd()
if ($processA.ExitCode -ne 0 -or $processB.ExitCode -ne 0) {
    throw "Falló P05. Nodo A: $errorA $outputA Nodo B: $errorB $outputB"
}

$verifySql = "SELECT count(*) FROM venta WHERE observacion='$marker';"
$deadline = [DateTimeOffset]::UtcNow.AddSeconds(20)
do {
    Start-Sleep -Milliseconds 200
    $countA = (Invoke-FarmaciaPsql -Settings $config -Port 5433 -Database $config['POSTGRES_DB'] -Sql $verifySql -TuplesOnly | Out-String).Trim()
    $countB = (Invoke-FarmaciaPsql -Settings $config -Port 5434 -Database $config['POSTGRES_DB'] -Sql $verifySql -TuplesOnly | Out-String).Trim()
} while (($countA -ne '2' -or $countB -ne '2') -and [DateTimeOffset]::UtcNow -lt $deadline)

if ($countA -ne '2' -or $countB -ne '2') { throw "P05 no convergió: Nodo A=$countA, Nodo B=$countB. Marcador de prueba: $marker" }
Write-Host "P05 aprobada: dos ventas insertadas en paralelo convergieron en ambos nodos. Marcador: $marker"
Write-Host 'Se conservan esas dos filas para que se pueda revisar la demostración; se pueden borrar desde Nodo A usando el marcador mostrado.'
