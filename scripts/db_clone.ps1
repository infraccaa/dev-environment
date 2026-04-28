param(
  [Parameter(Mandatory = $true)][string]$DbServer,
  [Parameter(Mandatory = $true)][string]$Source,
  [Parameter(Mandatory = $true)][string]$Target
)

# TODO_MANUAL: implementar dump/restore conforme engine (SQLServer/MySQL/PostgreSQL)
Write-Host "DB clone pending implementation: $Source -> $Target on $DbServer"
