$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)

if (-not (Test-Path -LiteralPath '.env')) {
    Copy-Item -LiteralPath '.env.example' -Destination '.env'
    Write-Host 'Se creó .env con credenciales locales de demostración.'
}

docker compose up -d nodo-a nodo-b
if ($LASTEXITCODE -ne 0) { throw 'No se pudieron iniciar los nodos. Revisa que Docker Desktop esté activo.' }

docker compose run --rm configurar-replicacion
if ($LASTEXITCODE -ne 0) { throw 'Falló la configuración de las suscripciones. Revisa docker compose logs.' }

Write-Host ''
Write-Host 'Nodos listos para pgAdmin:'
Write-Host '  Nodo A: localhost, puerto 5433'
Write-Host '  Nodo B: localhost, puerto 5434'
Write-Host '  Base de datos: farmacia'
Write-Host '  Usuario: revisa POSTGRES_USER en .env'
