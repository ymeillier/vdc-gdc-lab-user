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
