function Import-FarmaciaConfig {
    param([Parameter(Mandatory)][string]$ProjectRoot)

    $envFile = Join-Path $ProjectRoot '.env'
    if (-not (Test-Path -LiteralPath $envFile)) {
        Copy-Item -LiteralPath (Join-Path $ProjectRoot '.env.example') -Destination $envFile
        Write-Host 'Se creó .env con la configuración local de ejemplo.'
    }

    $settings = @{}
    foreach ($line in Get-Content -LiteralPath $envFile) {
        if ($line -match '^\s*#' -or $line -notmatch '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\s*$') { continue }
        $name = $Matches[1]
        $value = $Matches[2].Trim()
        if ($value.Length -ge 2 -and (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'")))) {
            $value = $value.Substring(1, $value.Length - 2)
        }
        $settings[$name] = $value
    }

    foreach ($required in @('PG_BIN', 'POSTGRES_DB', 'POSTGRES_USER', 'POSTGRES_PASSWORD', 'REPLICATION_PASSWORD')) {
        if (-not $settings.ContainsKey($required) -or [string]::IsNullOrWhiteSpace($settings[$required])) {
            throw "Falta el valor $required en .env."
        }
    }
    if ($settings['POSTGRES_DB'] -notmatch '^[a-zA-Z_][a-zA-Z0-9_]*$') { throw 'POSTGRES_DB debe usar solo letras, números y guion bajo.' }
    if ($settings['POSTGRES_USER'] -notmatch '^[a-zA-Z_][a-zA-Z0-9_]*$') { throw 'POSTGRES_USER debe usar solo letras, números y guion bajo.' }

    $settings['DATA_ROOT'] = Join-Path $env:LOCALAPPDATA 'FarmaciaReplicacion'
    foreach ($binary in @('initdb.exe', 'postgres.exe', 'pg_ctl.exe', 'psql.exe', 'createdb.exe')) {
        if (-not (Test-Path -LiteralPath (Join-Path $settings['PG_BIN'] $binary))) {
            throw "No encuentro $binary en $($settings['PG_BIN']). Ajusta PG_BIN en .env."
        }
    }
    return $settings
}

function Get-FarmaciaNodePath {
    param([Parameter(Mandatory)][hashtable]$Settings, [Parameter(Mandatory)][ValidateSet('nodo-a','nodo-b')][string]$Node)
    return Join-Path $Settings['DATA_ROOT'] $Node
}

function Invoke-FarmaciaPsql {
    param(
        [Parameter(Mandatory)][hashtable]$Settings,
        [Parameter(Mandatory)][ValidateSet(5433,5434)][int]$Port,
        [Parameter(Mandatory)][string]$Database,
        [string]$Sql,
        [string]$File,
        [switch]$TuplesOnly
    )

    $psql = Join-Path $Settings['PG_BIN'] 'psql.exe'
    $arguments = @('-X', '-v', 'ON_ERROR_STOP=1', '-h', '127.0.0.1', '-p', "$Port", '-U', $Settings['POSTGRES_USER'], '-d', $Database)
    if ($TuplesOnly) { $arguments += @('-t', '-A') }
    if ($File) { $arguments += @('-f', $File) }
    elseif ($null -ne $Sql) { $arguments += @('-c', $Sql) }
    else { throw 'Invoke-FarmaciaPsql requiere Sql o File.' }

    $previousPassword = $env:PGPASSWORD
    $env:PGPASSWORD = $Settings['POSTGRES_PASSWORD']
    try {
        $output = & $psql @arguments
        $exitCode = $LASTEXITCODE
    } finally {
        $env:PGPASSWORD = $previousPassword
    }
    if ($exitCode -ne 0) { throw "psql falló en el puerto $Port con código $exitCode." }
    return $output
}

function ConvertTo-SqlLiteral {
    param([Parameter(Mandatory)][string]$Value)
    return "'" + $Value.Replace("'", "''") + "'"
}

function ConvertTo-LibpqValue {
    param([Parameter(Mandatory)][string]$Value)
    $escaped = $Value.Replace('\', '\\').Replace("'", "\'")
    return "'" + $escaped + "'"
}

function Write-FarmaciaTemporarySql {
    param([Parameter(Mandatory)][string]$Sql)
    $file = New-TemporaryFile
    [System.IO.File]::WriteAllText([string]$file, $Sql + "`n", [System.Text.UTF8Encoding]::new($false))
    return [string]$file
}
