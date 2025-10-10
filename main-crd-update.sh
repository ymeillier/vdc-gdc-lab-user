# !/bin/bash

## Optional Script to be run on its own for updating the chrome remote desktop short lived token and redeploying the windows jump-host for reconfiguring CRD access to it


#clear

# Get the absolute path of the script itself
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
ABSOLUTE_SCRIPT_PATH="${SCRIPT_DIR}/${SCRIPT_NAME}"




#printf "▶️  Recreate and update crd auth token for win jump host chrome remote desktop configuration: \033[1;31m'Press Enter to proceed'\033[0m "
#read -r -p ""
#printf ''

WORKING_DIR=${SCRIPT_DIR}
AUTH_FILE="${WORKING_DIR}/assets-jump-host/crd-auth-command.txt"

if [[ -z "$PROJECT" ]]; then
read -p '👉 PROJECT variable undefined, confirm the Google project of the windows jump host to redeploy: ' PROJECT

fi
printf "\n"
#printf "⚠️ Redeploying win jump host from \033[1;33m'project ${PROJECT}'\033[0m. \033[1;31m'Press Enter to continue'\033[0m\n"
printf "    ⚠️ Redeploying win jump host from \033]8;;https://console.cloud.google.com/compute/instances?project=${PROJECT}\033\\ \033[1;34m'project ${PROJECT}'\033[0m \033]8;;\033\\. \033[1;31m'Press Enter to continue'\033[0m"
read -p ""
printf '\n'


# Get the current gcloud account from configuration
GCLOUD_ACCOUNT=$(gcloud config get-value account 2>/dev/null)

# Check if gcloud account is configured
if [[ -z "$GCLOUD_ACCOUNT" ]]; then
  printf '\n❌ No gcloud account is currently configured.\n'
  printf '👉 Please run "gcloud auth login" first to authenticate with your Google account.\n'
  printf "     ⚠️ Then re-run this script.\n"
  exit 1
fi

printf '✅ Using configured gcloud account: \033[1;32m%s\033[0m\n' "$GCLOUD_ACCOUNT"

# Verify authentication is still valid
if ! gcloud auth list --filter="status:ACTIVE" --format="value(account)" | grep -q "^${GCLOUD_ACCOUNT}$"; then
  printf '    🔄 Re-authenticating as %s...\n' "$GCLOUD_ACCOUNT"
  gcloud auth login "$GCLOUD_ACCOUNT" --force
  printf '    ✅ Authentication complete.\n'
else
  printf '    ✅ Authentication is active for %s\n' "$GCLOUD_ACCOUNT"
fi


printf '\n'
#printf "⚠️  This will redeploy the win-jh-XXXX instance from \033[1;32m'${PROJECT}'\033[0m. \033[1;31m'Press Enter to Continue'\033[0m or \033[1;31m'Ctrl+C to abort'\033[0m "
#read -r -p ""

printf "    👉 Paste the \033[1;31m'Windows (Cmd)'\033[0m from \033[1;34m'https://remotedesktop.google.com/headless'\033[0m (Begin -> Next -> Authorize): "
read -r crd_auth_command
echo "$crd_auth_command" > "$AUTH_FILE"

printf "    🔄 Regenerating PowerShell startup script with new CRD token...\n"

# Make scripts executable
chmod +x "${WORKING_DIR}/assets-jump-host/scripts/get_crd_auth.sh"
chmod +x "${WORKING_DIR}/assets-jump-host/scripts/sysprep.sh"

# Generate the base PowerShell script using sysprep.sh
. "${WORKING_DIR}/assets-jump-host/scripts/sysprep.sh"

# Move the generated script to the assets-jump-host directory
mv "${WORKING_DIR}/crd-sysprep-script.ps1" "${WORKING_DIR}/assets-jump-host/crd-sysprep-script.ps1"

# Append the additional setup commands from append-script.ps1
cat "${WORKING_DIR}/assets-jump-host/scripts/append-script.ps1" >> "${WORKING_DIR}/assets-jump-host/crd-sysprep-script.ps1"

# Add the admin user to Administrators group
cat << 'EOF' > add_to_group.ps1
# Add the 'admin' user to the local Administrators group
try {
  Add-LocalGroupMember -Group "Administrators" -Member "admin"
  Write-Host "User 'admin' added to the Administrators group."
}
catch {
  Write-Error "Failed to add 'admin' to Administrators group: $($_.Exception.Message)"
}
EOF

# Insert the admin group addition after the password update line
if [[ "$(uname -s)" == "Darwin" ]]; then
  # This block runs on macOS
  sed -i '' '/Write-Host "Password for user '\''admin'\'' has been updated."/r add_to_group.ps1' "${WORKING_DIR}/assets-jump-host/crd-sysprep-script.ps1"
elif [[ "$(uname -s)" == "Linux" ]]; then
  # This block runs on Linux and other OS
  sed -i '/Write-Host "Password for user '\''admin'\'' has been updated."/r add_to_group.ps1' "${WORKING_DIR}/assets-jump-host/crd-sysprep-script.ps1"
else
  printf "    ⚠️ OS not Darwin or Linux. Please verify the PowerShell script was generated correctly.\n"
fi

# Clean up temporary file
rm add_to_group.ps1

# Add additional software installations
cat << 'EOF' >> "${WORKING_DIR}/assets-jump-host/crd-sysprep-script.ps1"

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

EOF

printf "    ✅ PowerShell startup script regenerated with new CRD token.\n"

printf "    🔄 Updating jump host with non-expired CRD short lived token...\n"
terraform apply -replace="google_compute_instance.win_jh" -auto-approve

INSTANCE=$(gcloud compute instances list --filter="name ~ ^win-jh" --format="value(name)")

printf "👊 Infrastructure deployed. Links to environment: \n"
printf "    ✅ gcp project: 'https://console.cloud.google.com/compute/instances?project=${PROJECT}'\n"
printf "    ✅ Jump host \033[1;32m'${INSTANCE}'\033[0m Chrome Remote Desktop Access: \033[1;34m'https://remotedesktop.google.com/access/'\033[0m (with \033[1;32m'${GCLOUD_ACCOUNT}'\033[0m chrome profile) \n"
printf "\n"
