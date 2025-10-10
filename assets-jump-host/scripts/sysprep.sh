#!/bin/bash
# Generates sysprep startup script. See https://cloud.google.com/architecture/chrome-desktop-remote-windows-compute-engine#create_the_startup_script

cat << "EOF" > crd-sysprep-script.ps1
<#
    .SYNOPSIS
    GCESysprep specialize script for unattended Chrome Remote Desktop installation.
#>
$ErrorActionPreference = 'stop'

function Get-Metadata([String]$metadataName) {
  try {
    $value = (Invoke-RestMethod `
        -Headers @{'Metadata-Flavor' = 'Google'} `
        -Uri "http://metadata.google.internal/computeMetadata/v1/instance/attributes/$metadataName")
  }
  catch {
    # Report but ignore REST errors.
    Write-Host $_
  }
  if ($value -eq $null -or $value.Length -eq 0) {
    throw "Metadata value for ""$metadataName"" not specified. Skipping Chrome Remote Desktop service installation."
  }
  return $value
}

# Get config from metadata
#
$crdCommand = Get-Metadata('crd-command')
$crdPin = Get-Metadata('crd-pin')
$crdName = Get-Metadata('crd-name')

if ($crdPin -isNot [Int32] -or $crdPin -gt 999999 -or $crdPin -lt 0) {
  throw "Metadata ""crd-pin""=""$crdPin"" is not a 6 digit number. Skipping Chrome Remote Desktop service installation."
}
# Prefix $crdPin with zeros if required.
$crdPin = $crdPin.ToString("000000");

# Extract the authentication code and redirect URL arguments from the
# remote dekstop startup command line.
#
$crdCommandArgs = $crdCommand.Split(' ')
$codeArg = $crdCommandArgs | Select-String -Pattern '--code="[^"]+"'
$redirectArg = $crdCommandArgs | Select-String -Pattern '--redirect-url="[^"]+"'

if (-not $codeArg) {
  throw 'Cannot get --code= parameter from crd-command. Skipping Chrome Remote Desktop service installation.'
}
if (-not $redirectArg) {
  throw 'Cannot get --redirect-url= parameter from crd-command. Skipping Chrome Remote Desktop service installation.'
}

Write-Host 'Downloading Chrome Remote Desktop.'
$installer = "$env:TEMP\chromeremotedesktophost.msi"
$uri = 'https://dl.google.com/edgedl/chrome-remote-desktop/chromeremotedesktophost.msi'
(New-Object Net.WebClient).DownloadFile($uri,"$installer")
Write-Host 'Installing Chrome Remote Desktop.'
& msiexec.exe /I $installer /qn /quiet | Out-Default
Remove-Item $installer

Write-Host 'Starting Chrome Remote Desktop service.'
& "${env:ProgramFiles(x86)}\Google\Chrome Remote Desktop\CurrentVersion\remoting_start_host.exe" `
    $codeArg $redirectArg --name="$crdName" -pin="$crdPin" | Out-Default

Write-Host 'Downloading Chrome.'
$installer = "$env:TEMP\chrome_installer.exe"
$uri = 'https://dl.google.com/chrome/install/latest/chrome_installer.exe'
(New-Object Net.WebClient).DownloadFile($uri,"$installer")
Write-Host 'Installing Chrome.'
& $installer /silent /install | Out-Default
Remove-Item $installer

EOF
