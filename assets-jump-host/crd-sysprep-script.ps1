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

Write-Host "Create user 'admin'"
$crdPass = Get-Metadata('crd-pass')

$newPassword = ConvertTo-SecureString $crdPass -AsPlainText -Force 

# Create the "admin" user if it doesn't exist
if (!(Get-LocalUser -Name "admin" -ErrorAction SilentlyContinue)) {
  Write-Host "Creating local user 'admin'."
  #New-LocalUser -Name "admin" -Description "Administrator account" -NoPassword
  New-LocalUser -Name "admin" -Description "Administrator account" -Password $newPassword
}

# Set the new password for the "admin" user (INSECURE - DO NOT USE IN PRODUCTION)
#Set-LocalUser -Name "admin" -Password $newPassword 

Write-Host "Password for user 'admin' has been updated."
# Add the 'admin' user to the local Administrators group
try {
  Add-LocalGroupMember -Group "Administrators" -Member "admin"
  Write-Host "User 'admin' added to the Administrators group."
}
catch {
  Write-Error "Failed to add 'admin' to Administrators group: $($_.Exception.Message)"
}


# Get the desired display mode (1920x1080)
$displayMode = Get-WmiObject -Class Win32_DisplayMode -Filter "ScreenWidth=1920 AND ScreenHeight=1080"
# Set the display mode as the default for all users
$displayMode.SetAsDefault()


# # Install Git 
# Write-Host 'Downloading Git.'
# $installer = "$env:TEMP\git_installer.exe"
# $uri = 'https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.2/Git-2.47.1.2-64-bit.exe'
# (New-Object Net.WebClient).DownloadFile($uri,"$installer")
# Write-Host 'Installing Git with default settings and cmd.exe as terminal.'
# & $installer /SILENT /COMPONENTS="icons,ext\shellhere,ext\guihere,assoc,assoc_sh,gitlfs,gitcreds" /TERMINAL=cmd /NOCERTIFICATE /NORESTART | Out-Default
# Remove-Item $installer
# Write-Host 'Git installation complete.'


# # Install gcloud cli
# # --- Install gcloud CLI ---
# Write-Host 'Downloading gcloud CLI installer.'
# $installer = "$env:Temp\GoogleCloudSDKInstaller.exe"
# $uri = 'https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe'
# (New-Object Net.WebClient).DownloadFile($uri,"$installer")
# Write-Host 'Installing gcloud sdk.'
# & $installer /silent /install /install_python | Out-Default 
# Remove-Item $installer    
# Write-Host 'gcloud CLI installation complete.'



# # Install mRemoteNG
# $mRemoteNGInstaller = "$env:TEMP\mRemoteNG.msi"
# # Download the installer
# Invoke-WebRequest -Uri "https://mremoteng.org/download/latest" -OutFile $mRemoteNGInstaller
# # Install mRemoteNG silently
# Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $mRemoteNGInstaller /qn /norestart" -Wait
# # Remove the installer (optional)
# Remove-Item $mRemoteNGInstaller

# Install Git
Write-Host 'Downloading Git.'
$installer = "$env:TEMP\git_installer.exe"
$uri = 'https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.2/Git-2.47.1.2-64-bit.exe'
(New-Object Net.WebClient).DownloadFile($uri,"$installer")
Write-Host 'Installing Git with default settings and cmd.exe as terminal.'
& $installer /SILENT /COMPONENTS="icons,ext\shellhere,ext\guihere,assoc,assoc_sh,gitlfs,gitcreds" /TERMINAL=cmd /NOCERTIFICATE /NORESTART | Out-Default
Remove-Item $installer
Write-Host 'Git installation complete.'


# Install gcloud cli
# --- Install gcloud CLI ---
Write-Host 'Downloading gcloud CLI installer.'
$installer = "$env:Temp\GoogleCloudSDKInstaller.exe"
$uri = 'https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe'
(New-Object Net.WebClient).DownloadFile($uri,"$installer")
Write-Host 'Installing gcloud sdk.'
& $installer /silent /install /install_python | Out-Default
Remove-Item $installer
Write-Host 'gcloud CLI installation complete.'


# Install mRemoteNG

# Define variables
$zipUrl = "https://github.com/mRemoteNG/mRemoteNG/releases/download/20250815-v1.78.2-NB-(3131)/mRemoteNG-20250815-v1.78.2-NB-3131.zip"
$tempZipFile = "$env:TEMP\mRemoteNG-package.zip"
$destinationFolder = "$env:USERPROFILE\Desktop\mRemoteNG"

# Download the zip package
Write-Host "Downloading mRemoteNG zip package..."
Invoke-WebRequest -Uri $zipUrl -OutFile $tempZipFile

# Create the destination folder on the desktop if it doesn't exist
Write-Host "Creating destination folder: $destinationFolder"
New-Item -Path $destinationFolder -ItemType Directory -Force | Out-Null

# Extract the contents of the zip file
Write-Host "Extracting mRemoteNG..."
Expand-Archive -Path $tempZipFile -DestinationPath $destinationFolder -Force

# Clean up the temporary zip file
Write-Host "Cleaning up temporary files..."
Remove-Item -Path $tempZipFile -Force

Write-Host "mRemoteNG has been successfully downloaded and extracted to the Desktop."

