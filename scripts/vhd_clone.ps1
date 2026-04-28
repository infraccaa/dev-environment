param(
  [Parameter(Mandatory = $true)][string]$TemplatePath,
  [Parameter(Mandatory = $true)][string]$TargetPath
)

Copy-Item -Path $TemplatePath -Destination $TargetPath -Force
Write-Host "VHD cloned to $TargetPath"
