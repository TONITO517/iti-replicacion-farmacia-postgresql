$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\common.ps1"
$projectRoot = Split-Path -Parent $PSScriptRoot
$config = Import-FarmaciaConfig -ProjectRoot $projectRoot

function Initialize-Node {
    param([string]$Node, [int]$Port)
    $dataDir = Get-FarmaciaNodePath -Settings $config -Node $Node
    New-Item -ItemType Directory -Force -Path $dataDir | Out-Null

    if (-not (Test-Path -LiteralPath (Join-Path $dataDir 'PG_VERSION'))) {
        if ((Get-ChildItem -Force -LiteralPath $dataDir | Measure-Object).Count -gt 0) {
            throw "La carpeta $dataDir tiene archivos pero no es un clúster PostgreSQL. No la modificaré."
        }

        $passwordFile = New-TemporaryFile
        try {
            [System.IO.File]::WriteAllText([string]$passwordFile, $config['POSTGRES_PASSWORD'] + "`n", [System.Text.UTF8Encoding]::new($false))
            & (Join-Path $config['PG_BIN'] 'initdb.exe') -D $dataDir -U $config['POSTGRES_USER'] --encoding=UTF8 --auth-local=scram-sha-256 --auth-host=scram-sha-256 "--pwfile=$passwordFile"
            if ($LASTEXITCODE -ne 0) { throw "initdb falló al crear $Node." }
        } finally {
            Remove-Item -LiteralPath ([string]$passwordFile) -Force -ErrorAction SilentlyContinue
        }

        $serverSettings = @(
            "listen_addresses = '127.0.0.1'",
            "port = $Port",
            'wal_level = logical',
            'max_wal_senders = 10',
            'max_replication_slots = 10',
            'max_worker_processes = 12',
            'track_commit_timestamp = on'
        )
        [System.IO.File]::AppendAllText((Join-Path $dataDir 'postgresql.conf'), "`n# Configuración del proyecto de farmacias`n" + ($serverSettings -join "`n") + "`n", [System.Text.UTF8Encoding]::new($false))
        $hbaRules = @(
            "`nhost all replicador 127.0.0.1/32 scram-sha-256",
            "host replication replicador 127.0.0.1/32 scram-sha-256",
            "host all replicador ::1/128 scram-sha-256",
            "host replication replicador ::1/128 scram-sha-256"
        ) -join "`n"
        [System.IO.File]::AppendAllText((Join-Path $dataDir 'pg_hba.conf'), $hbaRules + "`n", [System.Text.UTF8Encoding]::new($false))
    }

    $pgCtl = Join-Path $config['PG_BIN'] 'pg_ctl.exe'
    & $pgCtl -D $dataDir status *> $null
    if ($LASTEXITCODE -ne 0) {
        & $pgCtl -D $dataDir -l (Join-Path $dataDir 'server.log') -w -t 60 start
        if ($LASTEXITCODE -ne 0) { throw "No se pudo iniciar $Node. Revisa $(Join-Path $dataDir 'server.log')." }
    }
}

function Ensure-DatabaseAndSchema {
    param([int]$Port)
    $databaseExists = (Invoke-FarmaciaPsql -Settings $config -Port $Port -Database 'postgres' -Sql "SELECT 1 FROM pg_database WHERE datname = '$($config['POSTGRES_DB'])';" -TuplesOnly | Out-String).Trim()
    if ($databaseExists -ne '1') {
        Invoke-FarmaciaPsql -Settings $config -Port $Port -Database 'postgres' -Sql "CREATE DATABASE $($config['POSTGRES_DB']) WITH ENCODING 'UTF8';" | Out-Null
    }

    $roleExists = (Invoke-FarmaciaPsql -Settings $config -Port $Port -Database 'postgres' -Sql "SELECT 1 FROM pg_roles WHERE rolname = 'replicador';" -TuplesOnly | Out-String).Trim()
    $replicationPassword = ConvertTo-SqlLiteral $config['REPLICATION_PASSWORD']
    $roleSql = if ($roleExists -eq '1') {
        "ALTER ROLE replicador WITH LOGIN REPLICATION PASSWORD $replicationPassword;"
    } else {
        "CREATE ROLE replicador WITH LOGIN REPLICATION PASSWORD $replicationPassword;"
    }
    $tempRoleSql = Write-FarmaciaTemporarySql $roleSql
    try { Invoke-FarmaciaPsql -Settings $config -Port $Port -Database 'postgres' -File $tempRoleSql | Out-Null }
    finally { Remove-Item -LiteralPath $tempRoleSql -Force -ErrorAction SilentlyContinue }

    $schemaExists = (Invoke-FarmaciaPsql -Settings $config -Port $Port -Database $config['POSTGRES_DB'] -Sql "SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='sucursal';" -TuplesOnly | Out-String).Trim()
    if ($schemaExists -ne '1') {
        Invoke-FarmaciaPsql -Settings $config -Port $Port -Database $config['POSTGRES_DB'] -File (Join-Path $projectRoot 'database\init\01-esquema.sql') | Out-Null
        Invoke-FarmaciaPsql -Settings $config -Port $Port -Database $config['POSTGRES_DB'] -File (Join-Path $projectRoot 'database\init\02-publicacion.sql') | Out-Null
    } else {
        $publicationExists = (Invoke-FarmaciaPsql -Settings $config -Port $Port -Database $config['POSTGRES_DB'] -Sql "SELECT 1 FROM pg_publication WHERE pubname='pub_farmacia';" -TuplesOnly | Out-String).Trim()
        if ($publicationExists -ne '1') {
            Invoke-FarmaciaPsql -Settings $config -Port $Port -Database $config['POSTGRES_DB'] -File (Join-Path $projectRoot 'database\init\02-publicacion.sql') | Out-Null
        }
    }
    Invoke-FarmaciaPsql -Settings $config -Port $Port -Database 'postgres' -Sql "GRANT CONNECT ON DATABASE $($config['POSTGRES_DB']) TO replicador;" | Out-Null
}

function Ensure-Subscription {
    param([int]$LocalPort, [string]$SubscriptionName, [int]$RemotePort)
    $connectionParts = @(
        "host=$(ConvertTo-LibpqValue -Value '127.0.0.1')",
        "port=$(ConvertTo-LibpqValue -Value ([string]$RemotePort))",
        "dbname=$(ConvertTo-LibpqValue -Value $config['POSTGRES_DB'])",
        "user=$(ConvertTo-LibpqValue -Value 'replicador')",
        "password=$(ConvertTo-LibpqValue -Value $config['REPLICATION_PASSWORD'])"
    )
    $connectionLiteral = ConvertTo-SqlLiteral ($connectionParts -join ' ')
    $exists = (Invoke-FarmaciaPsql -Settings $config -Port $LocalPort -Database $config['POSTGRES_DB'] -Sql "SELECT 1 FROM pg_subscription WHERE subname='$SubscriptionName';" -TuplesOnly | Out-String).Trim()
    if ($exists -eq '1') {
        $sql = "ALTER SUBSCRIPTION $SubscriptionName CONNECTION $connectionLiteral;"
    } else {
        $sql = "CREATE SUBSCRIPTION $SubscriptionName CONNECTION $connectionLiteral PUBLICATION pub_farmacia WITH (copy_data = false, origin = 'none');"
    }
    $tempSql = Write-FarmaciaTemporarySql $sql
    try { Invoke-FarmaciaPsql -Settings $config -Port $LocalPort -Database $config['POSTGRES_DB'] -File $tempSql | Out-Null }
    finally { Remove-Item -LiteralPath $tempSql -Force -ErrorAction SilentlyContinue }
}

foreach ($node in @(@{ Name = 'nodo-a'; Port = 5433 }, @{ Name = 'nodo-b'; Port = 5434 })) {
    Initialize-Node -Node $node.Name -Port $node.Port
    Ensure-DatabaseAndSchema -Port $node.Port
}

Ensure-Subscription -LocalPort 5433 -SubscriptionName 'sub_desde_nodo_b' -RemotePort 5434
Ensure-Subscription -LocalPort 5434 -SubscriptionName 'sub_desde_nodo_a' -RemotePort 5433

Write-Host ''
Write-Host 'Los dos nodos PostgreSQL están listos para pgAdmin:'
Write-Host '  Nodo A: 127.0.0.1, puerto 5433'
Write-Host '  Nodo B: 127.0.0.1, puerto 5434'
Write-Host "  Base: $($config['POSTGRES_DB'])"
Write-Host "  Usuario administrador: $($config['POSTGRES_USER'])"
