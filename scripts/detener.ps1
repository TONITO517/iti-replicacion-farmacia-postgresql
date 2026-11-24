$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)
docker compose down
if ($LASTEXITCODE -ne 0) { throw 'No se pudieron detener los nodos.' }
Write-Host 'Nodos detenidos. Los datos se conservaron en los volúmenes de Docker.'
