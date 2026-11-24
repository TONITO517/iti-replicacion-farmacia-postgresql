$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\common.ps1"
$projectRoot = Split-Path -Parent $PSScriptRoot
$config = Import-FarmaciaConfig -ProjectRoot $projectRoot

foreach ($node in @(@{ Name = 'nodo-a'; Port = 5433 }, @{ Name = 'nodo-b'; Port = 5434 })) {
    $dataDir = Get-FarmaciaNodePath -Settings $config -Node $node.Name
    if (-not (Test-Path -LiteralPath (Join-Path $dataDir 'PG_VERSION'))) { continue }
    $pgCtl = Join-Path $config['PG_BIN'] 'pg_ctl.exe'
    & $pgCtl -D $dataDir status *> $null
    if ($LASTEXITCODE -eq 0) {
        & $pgCtl -D $dataDir -m fast -w -t 60 stop
        if ($LASTEXITCODE -ne 0) { throw "No se pudo detener $($node.Name)." }
    }
}
Write-Host 'Nodos detenidos. Los datos locales del proyecto se conservaron.'
