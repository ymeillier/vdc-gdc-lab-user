#! /bin/bash

# Function to clear all known GCP environment variables and configurations
clear_gcp_env_vars() {
    printf "    🧹 Clearing all GCP environment variables and configurations...\n"
    
    # Unset all known GCP environment variables
    unset GOOGLE_CLOUD_PROJECT
    unset CLOUDSDK_CORE_PROJECT
    unset GCLOUD_PROJECT
    unset PROJECT_ID
    unset GOOGLE_APPLICATION_CREDENTIALS
    unset CLOUDSDK_ACTIVE_CONFIG_NAME


    BILLING_ID_FILE=".billing_id"
    if [ -f "$BILLING_ID_FILE" ]; then
        rm "$BILLING_ID_FILE"       
    fi


    # Clear gcloud configurations
    gcloud config unset project >/dev/null 2>&1 || true
    gcloud config unset core/project >/dev/null 2>&1 || true
    gcloud config unset compute/zone >/dev/null 2>&1 || true
    gcloud config unset compute/region >/dev/null 2>&1 || true
    
    # Clear Application Default Credentials quota project
    gcloud auth application-default set-quota-project "" >/dev/null 2>&1 || true
    
    printf "    ✅ Environment cleanup complete\n"
}

# Function to force set project configuration with maximum authority
force_set_project() {
    local project_id="$1"
    printf "    🔧 Forcefully setting project configuration to: \033[1;31m'${project_id}'\033[0m\n"
    
    # Set gcloud config with maximum precedence
    gcloud config set project "${project_id}" >/dev/null 2>&1
    gcloud config set core/project "${project_id}" >/dev/null 2>&1
    
    # Export environment variables with highest precedence
    export CLOUDSDK_CORE_PROJECT="${project_id}"
    export GOOGLE_CLOUD_PROJECT="${project_id}"
    export PROJECT_ID="${project_id}"
    
    # Force ADC to use the correct project
    gcloud auth application-default set-quota-project "${project_id}" >/dev/null 2>&1 || true
    
    printf "    ✅ Project configuration forced to: \033[1;31m'${project_id}'\033[0m. Press Enter to Continue"
    read -r -p ""

}

### in new terminal, respecify existing prefix for an existing project: e.g. for vdc-09289, RANDOM_SUFFIX=09289
clear

printf '\nℹ️ \033[1;33mThis bash script (main.sh) goes through steps to set the parameters for the terraform deployment of the vDC-based GDC lab.\033[0mℹ️\n'

# CRITICAL: Clear all GCP environment variables at the very start
clear_gcp_env_vars

# Check if running for the first time
printf '\n'




read -p "❓ Are you running this script for the first time? (y/n) " -n 1 -r
echo
SAVED_FIRSTTIME=$REPLY
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    # Answer was not Y or y , that is No: Not the first time.
    CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null)
    if [ -n "$CURRENT_PROJECT" ]; then
        printf '\n'
        echo -e -n "❓ Is this for project \033[1;31m$CURRENT_PROJECT\033[0m? (y/n) "
        read -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            read -p "Enter the correct project ID: " PROJECT_ID
            force_set_project "$PROJECT_ID"
        else
            PROJECT_ID=$CURRENT_PROJECT
            force_set_project "$PROJECT_ID"
        fi
    else
        read -p "Enter the project ID: " PROJECT_ID
        force_set_project "$PROJECT_ID"
    fi
    if [[ $PROJECT_ID =~ ^vdc-([0-9]{5})$ ]]; then
        RANDOM_SUFFIX=${BASH_REMATCH[1]}
        export RANDOM_SUFFIX
  
        printf "    ✅ Extracted RANDOM_SUFFIX: \033[1;31m%s\033[0m\n" "$RANDOM_SUFFIX"
    fi
else
    ## It is the first time running
    CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null)
    if [ -n "$CURRENT_PROJECT" ]; then 
        printf "    🧹 Clearing existing gcloud project configuration...\n"
        gcloud config unset project >/dev/null 2>&1
        gcloud auth application-default set-quota-project "" >/dev/null 2>&1
        unset CLOUDSDK_CORE_PROJECT
    fi

    #clearing potential remnant of biling id file:
    BILLING_ID_FILE=".billing_id"
    if [ -f "$BILLING_ID_FILE" ]; then
        rm "$BILLING_ID_FILE"       
    fi


    CURRENT_ZONE=$(gcloud config get-value compute/zone 2>/dev/null)
    if [ -n "$CURRENT_ZONE" ]; then gcloud config unset compute/zone >/dev/null 2>&1; fi

    #if user answers Y, i.e. it is the first time running the script. Unset suffix so that it gets created. 
    
    if [ -n "$RANDOM_SUFFIX" ]; then
        unset RANDOM_SUFFIX
        #printf "Unset RANDOM_SUFFIX for new deployment.\n"
    fi
    if [ -n "$GCP_REGION" ]; then
        unset GCP_REGION
        #printf "Unset RANDOM_SUFFIX for new deployment.\n"
    fi
    if [ -n "$GCP_ZONE" ]; then
        unset GCP_ZONE
        #printf "Unset RANDOM_SUFFIX for new deployment.\n"
    fi
fi








# Get the absolute path of the script itself
SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$( cd "$( dirname "$SCRIPT_PATH" )" &> /dev/null && pwd )"
SCRIPT_NAME="$(basename "$SCRIPT_PATH")"
ABSOLUTE_SCRIPT_PATH="${SCRIPT_DIR}/${SCRIPT_NAME}"

# Check if the script is being sourced
# if [[ "$0" == *"/bash"* || "$0" == *"/zsh"* || "$0" == *"-bash"* || "$0" == *"-zsh"* ]]; 
# then
#     printf '\n'
# else
#     printf '\n❌ This script must be sourced. Please run with "\033[1;31m . ./main.sh \033[0m" instead of "\033[1;31m ./main.sh \033[0m".\n'
#     printf '\nExiting...\n'
#     
# fi

#Check that script is being run from proper location:

# Check if main.sh exists in the current directory
if [[ ! -f "main.sh" ]]; then
  printf '\nℹ️  This is your current directory: \033[1;31m%s\033[0m\n' "${PWD}"
  printf '\n    🚫 You must run this script from a directory containing main.sh'
  printf '\n    ⚠️  If you are running this from a parent directory, please cd into the correct directory first.'
  
  # Loop that repeats the warning every 5 seconds until user interrupts
  while true; do
    printf '\n🔄 Waiting for you to change to the correct directory... (Ctrl+C to exit)'
    sleep 5
    # Re-check if main.sh now exists (in case user moved to correct directory)
    if [[ -f "main.sh" ]]; then
      printf '\n    ✅ Found main.sh in current directory. Continuing...\n'
      break
    fi
  done
fi


WORKING_DIR=${PWD}






















printf '\n'
printf "▶️ Press Enter to proceed with the next step: \033[1;32m'Authenticate user'\033[0m"
read -r -p "" 

##Authenticate as your argolis admin user:
#printf "🔄 Authenticating user:\n"


CONFIG_FILE=~/.my_gcloud_app_config
# Check if the config file exists and load it
if [ -f "$CONFIG_FILE" ]; then
  source "$CONFIG_FILE"
fi

GCLOUD_ACCOUNT=""

if [[ -z "$GCLOUD_ACCOUNT" ]]; then
read -p '    👉 Enter the Google account you want to authenticate with (typically admin@<ldap>.altostrat.com): ' GCLOUD_ACCOUNT
echo "GCLOUD_ACCOUNT=${GCLOUD_ACCOUNT}" > "$CONFIG_FILE"
fi

# Check if the user entered a value
if [[ -z "$GCLOUD_ACCOUNT" ]]; then
  printf '\n.   🚫  No account provided. Exiting.\n'
  exit
fi
CURRENT_GCLOUD_ACCOUNT=$(gcloud config get-value account 2>/dev/null)




if [[ "$CURRENT_GCLOUD_ACCOUNT" == "$GCLOUD_ACCOUNT" ]]; then
  printf '    🔑 You are already authenticated as \033[1;31m'%s'\033[0m. Skipping login.\n' "$GCLOUD_ACCOUNT"
  printf "    🔑 Refreshing Application Default Credentials (ADC) for user ...\n"
  # this is to ensure that the ADC json is set for the user in case we were already authenticated as teh user after gcloud config set account only and the ADc was still set to another account
  gcloud auth application-default login #--no-browser
  printf '    ✅ ADC refresh completed for current user.\n'
else
  printf '    🔑 Authenticating as $GCLOUD_ACCOUNT...\n'
  gcloud auth login "$GCLOUD_ACCOUNT" --force --update-adc --quiet
  printf '    ✅ Authentication complete along with ADC refresh.\n'
fi

# CRITICAL: Refresh Application Default Credentials to ensure Terraform has project context

















printf '\n'
printf "▶️ Press Enter to proceed with the next step: \033[1;32m'GCP vDC Project'\033[0m"
read -r -p  ""
## Project:
#printf "🔄 Creating project:\n"

if [[ -z "$RANDOM_SUFFIX" ]]; then
  RANDOM_SUFFIX=$(printf "%05d" $((RANDOM % 100000)))
  printf "    ℹ️ The random suffix assigned to your lab is: \033[1;31m'${RANDOM_SUFFIX}'\033[0m.\n"
else
  printf '    ℹ️ Reusing the existing random suffix: \033[1;31m'${RANDOM_SUFFIX}'\033[0m.\n' 
fi
export RANDOM_SUFFIX





PROJECT_NAME="vdc-${RANDOM_SUFFIX}"

printf '    ℹ️ Your virtual datacenter project is: \033[1;31m'${PROJECT_NAME}'\033[0m.\n'

echo "$PROJECT_NAME" > ./main-info/vdc-project.txt



PROJECT_ID=$PROJECT_NAME

# CRITICAL: Force project configuration immediately after PROJECT_ID is determined
force_set_project "$PROJECT_ID"

# Additional safeguard - export environment variables to prevent old project references
export CLOUDSDK_CORE_PROJECT=${PROJECT_ID}
export GOOGLE_CLOUD_PROJECT=${PROJECT_ID}

# 1. Get the Organization ID
printf '    🔍 Getting your organization ID...\n'
ORGANIZATION_ID=$(gcloud organizations list --format="value(ID)" 2>/dev/null)
if [[ -z "$ORGANIZATION_ID" ]]; then
  printf '    ❌ ERROR: Failed to find an Organization ID. Ensure your account has access to one.\n'
fi
printf '    ✅ Found Organization ID: \033[1;31m'${ORGANIZATION_ID}'\033[0m.\n'












## Ensure user has required iam permissions:

printf '    🔍 Checking for required IAM permissions...\n'

# Check for Organization Admin role
printf '    🔍 Checking for roles/resourcemanager.organizationAdmin...\n'
ORG_ADMIN_ROLE=$(gcloud organizations get-iam-policy "$ORGANIZATION_ID" --flatten="bindings[].members" --format="table(bindings.role)" --filter="bindings.members:user:${GCLOUD_ACCOUNT}" | grep "roles/resourcemanager.organizationAdmin")

if [[ -z "$ORG_ADMIN_ROLE" ]]; then
  printf '    ❌ ERROR: User %s does not have the required role roles/resourcemanager.organizationAdmin.\n' "$GCLOUD_ACCOUNT"
  printf '    Please re-run the script with a user that has Organization Admin permissions.\n'
  exit 1
else
  printf '    ✅ User has roles/resourcemanager.organizationAdmin.\n'
fi

# Check and grant Folder Admin role
printf '    🔍 Checking for roles/resourcemanager.folderAdmin...\n'
FOLDER_ADMIN_ROLE=$(gcloud organizations get-iam-policy "$ORGANIZATION_ID" --flatten="bindings[].members" --format="table(bindings.role)" --filter="bindings.members:user:${GCLOUD_ACCOUNT}" | grep "roles/resourcemanager.folderAdmin")

if [[ -n "$FOLDER_ADMIN_ROLE" ]]; then
  printf '    ✅ User already has roles/resourcemanager.folderAdmin.\n'
else
  printf '    🔄 Assigning roles/resourcemanager.folderAdmin to user %s...\n' "$GCLOUD_ACCOUNT"
  gcloud organizations add-iam-policy-binding "$ORGANIZATION_ID" \
    --member="user:${GCLOUD_ACCOUNT}" \
    --role="roles/resourcemanager.folderAdmin" --condition=None > /dev/null 2>&1
  printf '    ✅ Role roles/resourcemanager.folderAdmin assigned.\n'
fi

# Check and grant Org Policy Admin role
printf '    🔍 Checking for roles/orgpolicy.policyAdmin...\n'
ORG_POLICY_ADMIN_ROLE=$(gcloud organizations get-iam-policy "$ORGANIZATION_ID" --flatten="bindings[].members" --format="table(bindings.role)" --filter="bindings.members:user:${GCLOUD_ACCOUNT}" | grep "roles/orgpolicy.policyAdmin")

if [[ -n "$ORG_POLICY_ADMIN_ROLE" ]]; then
  printf '    ✅ User already has roles/orgpolicy.policyAdmin.\n'
else
  printf '    🔄 Assigning roles/orgpolicy.policyAdmin to user %s...\n' "$GCLOUD_ACCOUNT"
  gcloud organizations add-iam-policy-binding "$ORGANIZATION_ID" \
    --member="user:${GCLOUD_ACCOUNT}" \
    --role="roles/orgpolicy.policyAdmin" --condition=None > /dev/null 2>&1
  printf '    ✅ Role roles/orgpolicy.policyAdmin assigned.\n'
fi














# 2. Define and find the folder
FOLDER_NAME="vdc-${RANDOM_SUFFIX}"
printf '    🔍 Checking for folder \033[1;31m'${FOLDER_NAME}'\033[0m...\n'














# Get the folder ID and suppress any errors if it doesn't exist
FOLDER_ID=$(gcloud resource-manager folders list --organization="$ORGANIZATION_ID" --filter="displayName=${FOLDER_NAME}" --format="value(ID)" 2>/dev/null)

# Create the folder if it does not exist
if [[ -z "$FOLDER_ID" ]]; then
  printf '    🔄 Folder does not exist. Creating \033[1;31m'${FOLDER_NAME}'\033[0m under organization \033[1;31m'${ORGANIZATION_ID}'\033[0m...\n'
  
  # Run the create command, but capture the exit status
  if gcloud resource-manager folders create --display-name="$FOLDER_NAME" --organization="$ORGANIZATION_ID" >/dev/null 2>&1; then
    printf '    ✅ Folder \033[1;31m'${FOLDER_NAME}'\033[0m created successfully.\n'
    # Wait for the folder to be listed
    printf "    ⏳ Waiting for the folder to become available...\n"
    while [[ -z "$FOLDER_ID" ]]; do
      sleep 5
      FOLDER_ID=$(gcloud resource-manager folders list --organization="$ORGANIZATION_ID" --filter="displayName=${FOLDER_NAME}" --format="value(ID)" 2>/dev/null)
    done
    printf '    ✅ Folder \033[1;31m'${FOLDER_NAME}'\033[0m now available with ID: \033[1;31m'${FOLDER_ID}'\033[0m.\n'
  else
    printf '    ❌ ERROR: Failed to create folder. Exiting.\n'
    exit 1
  fi
else
  printf '    ✅ Folder \033[1;31m'${FOLDER_NAME}'\033[0m already exists with ID: \033[1;31m'${FOLDER_ID}'\033[0m.\n'
fi

# 4. Create the vDC project under the folder
if gcloud projects describe "$PROJECT_NAME" >/dev/null 2>&1; then
  printf '    ✅ vDC GCP project \033[1;31m'${PROJECT_NAME}'\033[0m already exists. Skipping creation.\n' 
else
  printf "    🔄 Creating vDC GCP project \033[1;31m'${PROJECT_NAME}'\033[0m under folder \033[1;31m'${FOLDER_NAME}'\033[0m...\n"
  gcloud projects create "$PROJECT_NAME" --folder="$FOLDER_ID" > /dev/null 2>&1
  printf '    ✅ vDC GCP project created.\n'
fi

















# Set gcloud config to your project ID: 
printf '\n'
printf "▶️ Press Enter to proceed with the next step: \033[1;32m'Set gcloud config parameters'\033[0m"
read -r -p ""
#printf '🔄 Setting gcloud config configurations:\n'

CURRENT_GCLOUD_CONFIG_PROJECT=$(gcloud config get-value project 2>/dev/null)
if [[ "$CURRENT_GCLOUD_CONFIG_PROJECT" != "$PROJECT_ID" ]]; 
then
  printf "    🔄 Setting gcloud config to project \033[1;31m'${PROJECT_ID}'\033[0m...\n"
  gcloud config set project ${PROJECT_ID} > /dev/null 2>&1
else
  printf "    ✅ gcloud config already set to project \033[1;31m'${PROJECT_ID}'\033[0m\n"
fi

# # Always ensure quota project and environment variable are set correctly
# printf "    🔄 Ensuring quota project and environment variables are set...\n"
# 
# # Clear and refresh Application Default Credentials to remove any cached old project references
# printf "    🧹 Clearing cached Application Default Credentials...\n"
# gcloud auth application-default revoke > /dev/null 2>&1 || true
# gcloud auth application-default login --quiet > /dev/null 2>&1


# Set quota project and environment variables
gcloud auth application-default set-quota-project ${PROJECT_ID} > /dev/null 2>&1
export CLOUDSDK_CORE_PROJECT=${PROJECT_ID}
export GOOGLE_CLOUD_PROJECT=${PROJECT_ID}

# Verify the configuration
CONFIGURED_GCLOUD_CONFIG_PROJECT=$(gcloud config get-value project 2>/dev/null)
CONFIGURED_QUOTA_PROJECT=$(gcloud auth application-default print-access-token --quiet 2>/dev/null && gcloud config list --format="value(core.project)" 2>/dev/null || echo "Not set")

printf "    ✅ gcloud config project: \033[1;31m'${CONFIGURED_GCLOUD_CONFIG_PROJECT}'\033[0m\n"
printf "    ✅ ADC quota project refreshed for: \033[1;31m'${PROJECT_ID}'\033[0m\n"
printf "    ✅ Environment variables: CLOUDSDK_CORE_PROJECT=\033[1;31m'${CLOUDSDK_CORE_PROJECT}'\033[0m\n"

# Validate that no old project references remain
printf "    🔍 Validating no old project references remain...\n"
if gcloud auth list --filter="status:ACTIVE" --format="value(account)" > /dev/null 2>&1; then
    printf "    ✅ Active authentication confirmed for current user\n"
else
    printf "    ⚠️ Warning: Authentication may need to be refreshed\n"
    read -r -p ""
fi














## Associate billing account to project (required to enable services)

printf '\n'
printf "▶️ Press Enter to proceed with the next step: \033[1;32m'Associate Billing Account'\033[0m"
read -r -p  ""


# Associate billing account to project: 
BILLING_ID_FILE=".billing_id"
if [ ! -f "$BILLING_ID_FILE" ]; then
    # Prompt the user for the billing account ID
    while true; do
        printf "    👉 Please enter the billing account ID (\033[1;34m'https://console.cloud.google.com/billing'\033[0m): ⚠️ ID Pasted silently - Paste and hit Enter "
        read -rs BILLING_ACCOUNT_ID
        if [ -n "$BILLING_ACCOUNT_ID" ]; then
            break
        else
            printf "\n    ❌ Paste did not work. Please try again.\n"
        fi
    done
    # Save the entered ID to the .billing_id file for Terraform to read automatically
    echo "$BILLING_ACCOUNT_ID" > "$BILLING_ID_FILE"
    printf "\n    ℹ️ Saving billing account ID to '$BILLING_ID_FILE' for Terraform to use automatically.\n"
fi



# Associate billing account to project: 
#printf '🔄 Associating Billing Account to project:\n'
BILLING_INFO=$(gcloud beta billing projects describe ${PROJECT_ID} --format="json" 2> /dev/null)

BILLING_ENABLED=$(echo "${BILLING_INFO}" | jq -r .billingEnabled)

# If billing is not enabled, the script will proceed to link a billing account.
if [[ "${BILLING_ENABLED}" == "false" ]]; then
  #printf "    ❌ No billing account linked to project: \033[1;31m'${PROJECT_ID}'\033[0m. Linking now...\n"
  
  # Link the project to the specified billing account
  gcloud billing projects link ${PROJECT_ID} --billing-account=$(cat .billing_id) > /dev/null 2>&1
  printf "    ✅ Billing account linked to project \033[1;31m'${PROJECT_ID}'\033[0m.\n"
else
  # If billing is already enabled, the script will get the linked account name.
  LINKED_BILLING_ACCOUNT=$(echo "${BILLING_INFO}" | jq -r .billingAccountName)
  printf "    ✅ Project \033[1;31m'${PROJECT_ID}'\033[0m is already linked to billing account (saved to ./billing.txt)\n"
fi









## Enable compute API early to prevent errors with subsequent gcloud compute commands
printf '\n'
printf "▶️ Press Enter to proceed with the next step: \033[1;32m'Enable compute service API'\033[0m"
read -r -p ""

SERVICE_NAME="compute.googleapis.com"
printf "    ⏳ Enabling \033[1;31m'${SERVICE_NAME}'\033[0m\n"
gcloud services enable "${SERVICE_NAME}" --async > /dev/null 2>&1

while true; do
  SERVICE_STATUS=$(gcloud services list --filter="NAME=$SERVICE_NAME" --format="value(state)")
  
  if [[ "${SERVICE_STATUS}" == "ENABLED" ]]; then
    printf "    ✅ Service \033[1;31m'$SERVICE_NAME'\033[0m is now enabled.\n"
    break
  else
    printf "    ⏳ Waiting for service to finish being enabled...\n"
    sleep 1
  fi
done

## Enable Org Policy API
printf '\n'
printf "▶️ Press Enter to proceed with the next step: \033[1;32m'Enable Org Policy service API'\033[0m"
read -r -p ""

SERVICE_NAME="orgpolicy.googleapis.com"
printf "    ⏳ Enabling \033[1;31m'${SERVICE_NAME}'\033[0m\n"
gcloud services enable "${SERVICE_NAME}" --async > /dev/null 2>&1

while true; do
  SERVICE_STATUS=$(gcloud services list --filter="NAME=$SERVICE_NAME" --format="value(state)")
  
  if [[ "${SERVICE_STATUS}" == "ENABLED" ]]; then
    printf "    ✅ Service \033[1;31m'$SERVICE_NAME'\033[0m is now enabled.\n"
    break
  else
    printf "    ⏳ Waiting for service to finish being enabled...\n"
    sleep 1
  fi
done

SERVICE_NAME="cloudresourcemanager.googleapis.com"
printf "    ⏳ Enabling \033[1;31m'${SERVICE_NAME}'\033[0m\n"
gcloud services enable "${SERVICE_NAME}" --async > /dev/null 2>&1

while true; do
  SERVICE_STATUS=$(gcloud services list --filter="NAME=$SERVICE_NAME" --format="value(state)")
  
  if [[ "${SERVICE_STATUS}" == "ENABLED" ]]; then
    printf "    ✅ Service \033[1;31m'$SERVICE_NAME'\033[0m is now enabled.\n"
    break
  else
    printf "    ⏳ Waiting for service to finish being enabled...\n"
    sleep 1
  fi
done


# Add a loop to verify the API is actually ready to be used
printf "    ⏳ Verifying Org Policy API is ready for use...\n"
while ! gcloud org-policies list --project="$PROJECT_ID" >/dev/null 2>&1; do
    printf "    ⏳ API is enabled, but not yet ready. Retrying in 5 seconds...\n"
    sleep 5
done
printf "    ✅ Org Policy API is fully ready.\n"

printf '\n'
printf "▶️ Press Enter to proceed with the next step: \033[1;32m'Override Org Policy for SA Key Creation'\033[0m"
read -r -p ""

POLICY_FILE="./allow_sa_key_creation.yaml"
# cat > "$POLICY_FILE" << EOL
# constraint: "constraints/iam.disableServiceAccountKeyCreation"
# booleanPolicy:
#   enforced: false
# EOL
CONSTRAINT="iam.disableServiceAccountKeyCreation"
cat > "$POLICY_FILE" << EOL
name: projects/${PROJECT_ID}/policies/${CONSTRAINT}
spec:
  rules:
  - enforce: false
EOL





printf "    🔄 Overriding organization policy to allow SA key creation for project \033[1;31m'${PROJECT_ID}'\033[0m...\n"
gcloud org-policies set-policy "$POLICY_FILE" --project="$PROJECT_ID" >/dev/null 2>&1

# Wait for the policy to propagate
printf "    ⏳ Waiting for project-level policy to take effect...\n"
while true; do
  # For V2 policies, the output is structured differently. We check the 'enforce' field within the rules.
  # The output can be 'True' or 'False' (a string), or empty if not set.
  POLICY_STATE=$(gcloud org-policies describe iam.disableServiceAccountKeyCreation --project="$PROJECT_ID" --effective --format="value(spec.rules[0].enforce)")
  
  # We are looking for the state where enforcement is turned off, which is 'False'.
  # Convert to lowercase to handle both 'False' and 'false'
  if [[ "$(echo "$POLICY_STATE" | tr '[:upper:]' '[:lower:]')" == "false" ]]; then
    printf "    ✅ Project-level policy is now effective. SA key creation is allowed.\n"
    break
  else
    # The effective policy might still be the inherited one, which could be 'True' or not set.
    printf "    ⏳ Still waiting for policy override... Effective enforcement state: ${POLICY_STATE:-not set}\n"
    sleep 2
  fi
done

printf '\n'
printf "▶️ Press Enter to proceed with the next step: \033[1;32m'Configure Service Account for Automation'\033[0m"
read -r -p ""

# ### The "Why": Cloud Shell's Temporary Credentials
# 
# Cloud Shell provides a fantastic, ready-to-go environment, but for security reasons, the credentials it grants you are __temporary__. When you see the "Cloud Shell needs permission to use your credentials..." pop-up, it's because those temporary credentials have expired, and Cloud Shell needs your explicit, interactive consent to generate a new set.
# - __`gcloud auth login --update-adc`__ is the correct command to refresh your __Application Default Credentials (ADC)__, which is what Terraform uses.
# - __The Problem:__ This command still relies on your user identity. When the underlying session token expires, even the ADC becomes invalid, triggering the pop-up. A non-interactive script like `main.sh` cannot click the "Authorize" button, so any subsequent API call fails.
# 
# ### The Solution: Service Account Authentication
# The standard, production-grade solution for this is to stop authenticating as a human user and start authenticating as a __service account__.
# A service account is a special, non-human account designed specifically for applications and scripts. You create a private key file (a JSON file) for it, and your script uses that key to authenticate. This method is completely non-interactive and does not expire in the same way your user session does.
# 
# ### Implementation:
# 1. __Create a Service Account:__ New service account specifically for this Terraform automation.
# 2. __Grant Permissions:__ Give this service account the necessary IAM roles (e.g., `Project Owner`) to manage all the resources in your project.
# 3. __Generate a Key:__ Create and download a JSON key file for this service account.
# 4. __Exclude key push to git via .gitignore
# 5. __Update the Script:__ Use this key file in main.sh by setting the `GOOGLE_APPLICATION_CREDENTIALS` environment variable. This will cause `gcloud` and Terraform to authenticate as the service account, completely bypassing the interactive user login and the "Authorize" pop-up.
 






SA_NAME="terraform-automation-sa"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
KEY_DIR="${WORKING_DIR}/.keys"
KEY_FILE="${KEY_DIR}/${PROJECT_ID}-sa-key.json"

mkdir -p "$KEY_DIR"

# Check if the Service Account already exists
printf "    🔍 Checking for Service Account \033[1;31m'${SA_NAME}'\033[0m...\n"
if gcloud iam service-accounts describe "$SA_EMAIL" --project="$PROJECT_ID" >/dev/null 2>&1; then
  printf "    ✅ Service Account already exists.\n"
else
  printf "    🔄 Creating Service Account \033[1;31m'${SA_NAME}'\033[0m...\n"
  gcloud iam service-accounts create "$SA_NAME" \
    --display-name="Terraform Automation Service Account" \
    --project="$PROJECT_ID" --quiet > /dev/null 2>&1
  
  # Wait for the Service Account to propagate before continuing.
  printf "    ⏳ Waiting for Service Account to become available...\n"
  while ! gcloud iam service-accounts describe "$SA_EMAIL" --project="$PROJECT_ID" >/dev/null 2>&1; do
    printf "    ⏳ Still waiting for SA propagation...\n"
    sleep 2
  done
  printf "    ✅ Service Account is now available.\n"
fi






# Grant Owner role to the Service Account
printf "    🔄 Ensuring Service Account has 'Owner' role...\n"
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/owner" >/dev/null 2>&1

# Grant Org Policy Admin role to the Service Account
printf "    🔄 Ensuring Service Account has 'Org Policy Admin' role at org level...\n"
gcloud organizations add-iam-policy-binding $ORGANIZATION_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/orgpolicy.policyAdmin" >/dev/null 2>&1
#gcloud organizations add-iam-policy-binding $ORGANIZATION_ID --member="serviceAccount:${SA_EMAIL}" --role="roles/orgpolicy.policyAdmin"



# Grant additional roles to the Service Account for GDC project deployment
printf "    🔄 Ensuring Service Account has 'Billing Project Creator' role...\n"
gcloud billing accounts add-iam-policy-binding "$(cat .billing_id)" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/billing.projectCreator" >/dev/null 2>&1

printf "    🔄 Ensuring Service Account has 'Organization Viewer' role...\n"
gcloud organizations add-iam-policy-binding "$ORGANIZATION_ID" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/resourcemanager.organizationViewer" >/dev/null 2>&1

printf "    🔄 Ensuring Service Account has 'Billing Account Viewer' role...\n"
gcloud billing accounts add-iam-policy-binding "$(cat .billing_id)" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/billing.viewer" >/dev/null 2>&1


printf "    🔄 Ensuring Service Account has 'Billing Account User' role...\n"
gcloud billing accounts add-iam-policy-binding "$(cat .billing_id)" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/billing.user" >/dev/null 2>&1
#gcloud billing accounts add-iam-policy-binding "$(cat .billing_id)" --member="serviceAccount:${SA_EMAIL}" --role="roles/billing.user"

# gcloud billing accounts add-iam-policy-binding "$(cat .billing_id)" \
#     --member="serviceAccount:${SA_EMAIL}" \
#     --role="roles/billing.admin"

#gcloud billing accounts add-iam-policy-binding "$(cat .billing_id)" --member="serviceAccount:${SA_EMAIL}" --role="roles/billing.admin"



# Add a brief, final sleep to be absolutely sure the IAM binding has propagated.
printf "    ⏳ Wait 30 seconds for IAM permissions to propagate...\n"
sleep 30

printf "    ✅ Roles granted. Press Enter to continue and create the service account key..."
read -r -p ""











# Check if the key file already exists
if [ -f "$KEY_FILE" ]; then
  printf "    ✅ Service Account key file already exists at \033[1;31m'${KEY_FILE}'\033[0m.\n"
else
  printf "    🔄 Creating and downloading new Service Account key...\n"
  
  # Retry loop for key creation with diagnostics
  MAX_RETRIES=10
  RETRY_COUNT=0
  KEY_CREATED=false
  
  while [ $RETRY_COUNT -lt $MAX_RETRIES ] && [ "$KEY_CREATED" = false ]; do
    # if [ $RETRY_COUNT -gt 0 ]; then
    #   printf "    🔄 Retry attempt $RETRY_COUNT of $MAX_RETRIES...\n"
    #   
    #   # Add comprehensive diagnostics before retry
    #   printf "    🔍 Diagnostic Information:\n"
    #   printf "      📋 Target project for key creation: ${PROJECT_ID}\n"
    #   printf "      📋 Service account: ${SA_EMAIL}\n"
    #   printf "      📋 Current gcloud project: $(gcloud config get-value project 2>/dev/null)\n"
    #   printf "      📋 Current ADC project: $(gcloud auth application-default print-access-token --quiet 2>/dev/null && gcloud config get-value project 2>/dev/null || echo 'Failed to get ADC project')\n"
    #   
    #   printf "    🔍 Checking effective policy state on project ${PROJECT_ID}...\n"
    #   EFFECTIVE_POLICY=$(gcloud org-policies describe iam.disableServiceAccountKeyCreation --project="$PROJECT_ID" --effective --format="value(spec.rules[0].enforce)" 2>/dev/null)
    #   printf "    📊 Effective policy enforcement on ${PROJECT_ID}: '${EFFECTIVE_POLICY:-'not set'}'\n"
    #   
    #   printf "    ⏳ Waiting 15 seconds before retry...\n"
    #   sleep 15
    # fi
    printf "    🔍 Diagnostic Information:\n"
    printf "      📋 Target project for key creation: ${PROJECT_ID}\n"
    printf "      📋 Service account: ${SA_EMAIL}\n"
    printf "      📋 Current gcloud project: $(gcloud config get-value project 2>/dev/null)\n"
    printf "      📋 Current ADC project: $(gcloud config get billing/quota_project 2>/dev/null  || echo 'Failed to get ADC project')\n"

    printf "    🎯 Attempting key creation on project: ${PROJECT_ID}\n"
    KEY_CREATE_OUTPUT=$(gcloud iam service-accounts keys create "$KEY_FILE" \
        --iam-account="$SA_EMAIL" \
        --project="$PROJECT_ID" 2>&1)
    KEY_CREATE_STATUS=$?
    
    if [ $KEY_CREATE_STATUS -eq 0 ]; then
      KEY_CREATED=true
      printf "    ✅ Service Account key created successfully.\n"
    else
      RETRY_COUNT=$((RETRY_COUNT + 1))
      printf "    ⚠️ Key creation failed (attempt $RETRY_COUNT). Error details:\n"
      echo "$KEY_CREATE_OUTPUT" | sed 's/^/      /'
    fi
  done
  
  if [ "$KEY_CREATED" = false ]; then
    printf "    ❌ ERROR: Failed to create service account key after $MAX_RETRIES attempts.\n"
    printf "    🔍 Final diagnostics:\n"
    printf "      - Effective policy: $(gcloud org-policies describe iam.disableServiceAccountKeyCreation --project="$PROJECT_ID" --effective --format="value(spec.rules[0].enforce)" 2>/dev/null)\n"
    printf "      - Service account exists: $(gcloud iam service-accounts describe "$SA_EMAIL" --project="$PROJECT_ID" --format="value(email)" 2>/dev/null)\n"
    printf "    👉 This may indicate an organization-level policy restriction that cannot be overridden at the project level.\n"
    exit 1
  fi
fi

# CRITICAL: Validate the key file
if [ ! -s "$KEY_FILE" ]; then
    printf "    ❌ ERROR: Service Account key file at \033[1;31m'${KEY_FILE}'\033[0m is empty or was not created.\n"
    printf "    👉 Please check for errors in the previous steps and re-run the script.\n"
    exit 1
else
    printf "    ✅ Service Account key file validated.\n"
fi




# Add a final sleep to ensure the key is fully propagated before activation.
printf "    ⏳ Waiting for new key to propagate through Google's IAM system...\n"
sleep 10

# The key is now ready, but we will activate it just before the terraform apply command.
printf "    ✅ Service account key is ready. Continuing with user credentials for now.\n"


































  
# Check for existing pnetlab instance to derive region and zone
#printf "\n    🔍 Checking for project region and zone (if any set)...\n"
INSTANCE_INFO=$(gcloud compute instances list --filter="name~'^vdc-pnetlab-'" --format="value(name,zone)" --limit=1 2>/dev/null)

if [[ -n "$INSTANCE_INFO" ]]; then
  INSTANCE_NAME=$(echo "$INSTANCE_INFO" | awk '{print $1}')
  INSTANCE_ZONE=$(echo "$INSTANCE_INFO" | awk '{print $2}')
  
  if [[ -n "$INSTANCE_ZONE" ]]; then
    GCP_ZONE="$INSTANCE_ZONE"
    # Extract region from zone (e.g., us-central1-a -> us-central1)
    GCP_REGION="${GCP_ZONE%-*}"

    printf "    ✅ Found instance '\033[1;31m%s\033[0m' in zone '\033[1;31m%s\033[0m'.\n" "$INSTANCE_NAME" "$GCP_ZONE"
    printf "    ℹ️  Automatically setting GCP_REGION to '\033[1;31m%s\033[0m' and GCP_ZONE to '\033[1;31m%s\033[0m'.\n" "$GCP_REGION" "$GCP_ZONE"
    $(gcloud config set compute/region ${GCP_REGION} 2>/dev/null)
    $(gcloud config set compute/zone ${GCP_ZONE} 2>/dev/null)
    export GCP_REGION
    export GCP_ZONE
  fi
fi
  

if [ -f ".gcp_region" ]; then
    GCP_REGION=$(cat .gcp_region)
    printf "    ✅  Reused gcp region setting from local file .gcp_region \n"
fi

if [[ -z "$GCP_REGION" ]]; then
  printf '\n'
  printf "🔄 Setting gcloud config region:\n"
  
  # Get unique continents from available regions
  printf "    🔍 Getting available continents...\n"
  AVAILABLE_CONTINENTS=($(gcloud compute regions list --format="value(name)" | cut -d- -f1 | sort | uniq))
  
  # Check if any continents were found
  if [ ${#AVAILABLE_CONTINENTS[@]} -eq 0 ]; then
    printf "    ❌ ERROR: No regions found\n"
    exit 1
  fi
  
  # Display available continents
  printf "    📋 Available continents:\n"
  for i in "${!AVAILABLE_CONTINENTS[@]}"; do
    printf "      $((i+1))) \033[1;31m${AVAILABLE_CONTINENTS[i]}\033[0m\n"
  done
  
  
  # Get user continent selection with validation
  while true; do
    read -p "    👉 Enter your choice (1-${#AVAILABLE_CONTINENTS[@]}): " choice
    
    # Validate input is a number
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#AVAILABLE_CONTINENTS[@]}" ]; then
      SELECTED_CONTINENT="${AVAILABLE_CONTINENTS[$((choice-1))]}"
      printf "        ✅ Selected continent: \033[1;31m${SELECTED_CONTINENT}\033[0m\n"
      break
    else
      printf "        ❌ Invalid choice. Please enter a number between 1 and ${#AVAILABLE_CONTINENTS[@]}.\n"
    fi
  done
  printf "\n"
  # Get regions for the selected continent
  printf "    🔍 Getting available regions for continent \033[1;31m'${SELECTED_CONTINENT}'\033[0m...\n"
  AVAILABLE_REGIONS=($(gcloud compute regions list --format="value(name)" | grep "^${SELECTED_CONTINENT}-" | sort))
  
  # Check if any regions were found for the continent
  if [ ${#AVAILABLE_REGIONS[@]} -eq 0 ]; then
    printf "    ❌ ERROR: No regions found for continent \033[1;31m'${SELECTED_CONTINENT}'\033[0m\n"
    exit 1
  fi
  
  # Display available regions for the selected continent
  printf "    📋 Available regions in \033[1;31m'${SELECTED_CONTINENT}'\033[0m:\n"
  for i in "${!AVAILABLE_REGIONS[@]}"; do
    printf "      $((i+1))) \033[1;31m${AVAILABLE_REGIONS[i]}\033[0m\n"
  done
  
  
  # Get user region selection with validation
  while true; do
    read -p "    👉 Enter your choice (1-${#AVAILABLE_REGIONS[@]}): " choice
    
    # Validate input is a number
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#AVAILABLE_REGIONS[@]}" ]; then
      GCP_REGION="${AVAILABLE_REGIONS[$((choice-1))]}"
      printf "    ✅ Selected region: \033[1;31m${GCP_REGION}\033[0m\n"
      echo "$GCP_REGION" > .gcp_region
      break
    else
      printf "    ❌ Invalid choice. Please enter a number between 1 and ${#AVAILABLE_REGIONS[@]}.\n"
    fi
  done
fi


if [ -f ".gcp_zone" ]; then
    GCP_ZONE=$(cat .gcp_zone)
else
  # Get available zones for the selected region
  printf "\n    🔍 Getting available zones for region \033[1;31m'${GCP_REGION}'\033[0m...\n"
  
  # Get zones and store in array
  AVAILABLE_ZONES=($(gcloud compute zones list --filter="region:(${GCP_REGION})" --format="value(name)" 2>/dev/null))
  
  # Check if any zones were found
  if [ ${#AVAILABLE_ZONES[@]} -eq 0 ]; then
    printf "    ❌ ERROR: No zones found for region \033[1;31m'${GCP_REGION}'\033[0m\n"
    printf "    👉 Please verify the region name is correct.\n"
    exit 1
  fi
  
  # Display available zones
  printf "    📋 Available zones in region \033[1;31m'${GCP_REGION}'\033[0m:\n"
  for i in "${!AVAILABLE_ZONES[@]}"; do
    printf "      $((i+1))) \033[1;31m${AVAILABLE_ZONES[i]}\033[0m\n"
  done
  printf '\n'
  
  # Get user selection with validation
  while true; do
    read -p "    👉 Enter your choice (1-${#AVAILABLE_ZONES[@]}): " choice
    
    # Validate input is a number
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#AVAILABLE_ZONES[@]}" ]; then
      GCP_ZONE="${AVAILABLE_ZONES[$((choice-1))]}"
      printf "    ✅ Selected zone: \033[1;31m${GCP_ZONE}\033[0m\n"
      echo "$GCP_ZONE" > .gcp_zone
      break
    else
      printf "    ❌ Invalid choice. Please enter a number between 1 and ${#AVAILABLE_ZONES[@]}.\n"
    fi
  done
fi


CURRENT_GCLOUD_CONFIG_REGION=$(gcloud config get-value compute/region 2>/dev/null)

if [[ "$CURRENT_GCLOUD_CONFIG_REGION" != "$GCP_REGION" ]]; 
then
  printf "    🔄 Setting gcloud config region to \033[1;31m'$GCP_REGION'\033[0m...\n"
  gcloud config set compute/region ${GCP_REGION} --quiet >/dev/null
  CONFIGURED_GCLOUD_CONFIG_REGION=$(gcloud config get-value compute/region 2>/dev/null)
  printf "    ✅ gcloud config set to use region: \033[1;31m'${CONFIGURED_GCLOUD_CONFIG_REGION}'\033[0m\n"
else
  CONFIGURED_GCLOUD_CONFIG_REGION=$(gcloud config get-value compute/region 2>/dev/null)
  printf "\n"
  printf "🔄 Setting gcloud config region:\n"
  printf "    ✅ gcloud config already set to use region: \033[1;31m'${CONFIGURED_GCLOUD_CONFIG_REGION}'\033[0m\n"
fi




CURRENT_GCLOUD_CONFIG_ZONE=$(gcloud config get-value compute/zone 2>/dev/null)
if [[ "$CURRENT_GCLOUD_CONFIG_ZONE" != "$GCP_ZONE" ]]; 
then
  printf "    🔄 Setting gcloud config zone to \033[1;31m'$GCP_ZONE'\033[0m...\n"
  gcloud config set compute/zone ${GCP_ZONE} --quiet >/dev/null
  CONFIGURED_GCLOUD_CONFIG_ZONE=$(gcloud config get-value compute/zone 2>/dev/null)
  printf "    ✅ gcloud config set to use zone: \033[1;31m'${CONFIGURED_GCLOUD_CONFIG_ZONE}'\033[0m\n"
else
  CONFIGURED_GCLOUD_CONFIG_ZONE=$(gcloud config get-value compute/zone 2>/dev/null)
  printf "\n"
  printf "🔄 Setting gcloud config zone:\n"
  printf "    ✅ gcloud config already set to use zone: \033[1;31m'${CONFIGURED_GCLOUD_CONFIG_ZONE}'\033[0m\n"
fi

printf '\n'
printf '⚙️ gcloud configs summary:\n'
printf "    💡 core/account:     \033[1;31m%s\033[0m\n" "$(gcloud config get-value core/account 2> /dev/null)"
printf "    💡 core/project:     \033[1;31m%s\033[0m\n" "$(gcloud config get-value core/project 2> /dev/null)"
printf "    💡 compute/region:   \033[1;31m%s\033[0m\n" "$(gcloud config get-value compute/region 2> /dev/null)"
printf "    💡 compute/zone:     \033[1;31m%s\033[0m\n" "$(gcloud config get-value compute/zone 2> /dev/null)"


## below used to work when project was under the organization
#ORG_ID=$(gcloud projects describe "$PROJECT_NAME" --format="value(parent.id)")

ORG_ID=$(gcloud organizations list --format="value(ID)")












































printf '\n'
printf '\n'
printf "▶️ Press Enter to proceed with the next step: \033[1;32m'Check and cleanup terraform state and variables'\033[0m"
read -r -p ""

# Check for existing terraform state files
printf "    🔍 Checking for existing terraform state files...\n"
STATE_FILES_EXIST=false

if [[ -f "terraform.tfstate" || -f "terraform.tfstate.backup" ]]; then
  STATE_FILES_EXIST=true
  printf "    ⚠️  Found existing terraform state files:\n"
  [[ -f "terraform.tfstate" ]] && printf "      - terraform.tfstate\n"
  [[ -f "terraform.tfstate.backup" ]] && printf "      - terraform.tfstate.backup\n"
  
  printf "    👉 Do you want to delete these state files? (y/\033[1;31mn\033[0m) (🚨 picking yes would require a complete redeploy 🚨): "
  read -r REPLY


  echo # Move to a new line
  
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    [[ -f "terraform.tfstate" ]] && rm terraform.tfstate && printf "    ✅ Deleted terraform.tfstate\n"
    [[ -f "terraform.tfstate.backup" ]] && rm terraform.tfstate.backup && printf "    ✅ Deleted terraform.tfstate.backup\n"
  else
    printf "    ℹ️  Keeping existing state files.\n"
  fi
else
  printf "    ✅ No existing terraform state files found.\n"
fi

# Check for populated terraform variables
printf "\n    🔍 Checking terraform variable files...\n"
VARS_POPULATED=false

# Check main terraform.tfvars
if grep -q '^gcp_orgid = "[^"]\+"\|^gcp_project = "[^"]\+"\|^user_account = "[^"]\+"' terraform.tfvars 2>/dev/null; then
  VARS_POPULATED=true
fi

# Check GDC terraform.tfvars
if grep -q '^user_account = "[^"]\+"\|^orgid = "[^"]\+"\|^gcp_region = "[^"]\+"' gdc-gcp-project/tf/terraform-gdc.auto.tfvars 2>/dev/null; then
  VARS_POPULATED=true
fi

if [[ "$VARS_POPULATED" == "true" ]]; then
  printf "    ⚠️  Found populated terraform variables in configuration files.\n"
  
  # Show current content of terraform.tfvars
  printf "        📄 Current content of terraform.tfvars (press Enter to continue):"
  read -r -p ""
  printf "\n    ────────────────────────────────────────\n"
  cat terraform.tfvars | sed 's/^/    /'
  printf "    ────────────────────────────────────────\n"
  
  # Show current content of GDC terraform.tfvars
  printf "        📄 Current content of gdc-gcp-project/tf/terraform-gdc.auto.tfvars (press Enter to continue):"
  #read -r -p ""
  printf "    ────────────────────────────────────────\n"
  cat gdc-gcp-project/tf/terraform-gdc.auto.tfvars | sed 's/^/    /'
  printf "    ────────────────────────────────────────\n"
  

  

  # Check if this is the first time running the script
  if [[ $SAVED_FIRSTTIME =~ ^[Yy]$ ]] || [[ $SAVED_FIRSTTIME =~ ^[Yy][Ee][Ss]$ ]]; then
    # First time running - automatically set to 'y' (reset and populate with current project)
    REPLY="y"
    printf "    ℹ️  First time deployment detected - will populate terraform variables with current project configuration.\n"
  else
    # Not first time - ask the user
    read -p "    👉 Do you want to reset terraform variables to empty values? (y/n): " -n 1 -r
    echo # Move to a new line
  fi
  
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    printf "        🔄 Resetting terraform.tfvars from template...\n"
    cp terraform.tfvars.tpl terraform.tfvars
    printf "        ✅ Have reset terraform.tfvars using terraform.tfvars.tpl template\n"

    printf "\n        🔄 Resetting gdc-gcp-project/tf/terraform-gdc.auto.tfvars from template...\n"
    cp gdc-gcp-project/tf/terraform-gdc.auto.tfvars.tpl gdc-gcp-project/tf/terraform-gdc.auto.tfvars
    printf "        ✅ Have reset gdc-gcp-project/tf/terraform-gdc.auto.tfvars\n"

    
    printf '\n'
    printf "▶️ Press Enter to proceed with the next step: \033[1;32m'Populate variables into terraform variables file'\033[0m"
    read -r -p ""
    ##populate terraform.tfvars:
    #printf "🔄 Updating terraform.tfvars variables ...\n"
    # Configs summary:

    PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_NAME" --format="value(projectNumber)")
    printf '    ⚙️ GCP Configurations Summary :\n'
      printf '      💡 Project name is:   \033[1;31m%s\033[0m\n' "$PROJECT_NAME"
      printf '      💡 Project ID is:     \033[1;31m%s\033[0m\n' "$PROJECT_ID"
      printf '      💡 Project number is: \033[1;31m%s\033[0m\n' "$PROJECT_NUMBER"
      printf '      💡 Organization ID is: \033[1;31m%s\033[0m\n' "$ORG_ID"
      printf '      💡 Region: \033[1;31m%s\033[0m\n' "$GCP_REGION"
      printf '      💡 Zone: \033[1;31m%s\033[0m\n' "$GCP_ZONE"


    if [[ "$(uname -s)" == "Darwin" ]]; then
  # This block runs on macOS
  sed -i '' "s|^gcp_orgid =.*|gcp_orgid = \"$ORG_ID\"|" terraform.tfvars
  sed -i '' "s|^gcp_project =.*|gcp_project = \"$PROJECT_ID\"|" terraform.tfvars
  sed -i '' "s|^gcp_region =.*|gcp_region = \"$GCP_REGION\"|" terraform.tfvars
  sed -i '' "s|^gcp_zone =.*|gcp_zone = \"$GCP_ZONE\"|" terraform.tfvars
  sed -i '' "s|^gcp_project_number =.*|gcp_project_number = \"$PROJECT_NUMBER\"|" terraform.tfvars
  sed -i '' "s|^gcp_project_folder_id =.*|gcp_project_folder_id = \"$FOLDER_ID\"|" terraform.tfvars
  sed -i '' "s|^user_account =.*|user_account = \"$GCLOUD_ACCOUNT\"|" terraform.tfvars
  sed -i '' "s|^svc_account =.*|svc_account = \"$SA_EMAIL\"|" terraform.tfvars
  sed -i '' "s|^path_module =.*|path_module = \"$PWD\"|" terraform.tfvars
  
  # Update GDC terraform.tfvars
  sed -i '' "s|^user_account =.*|user_account = \"$GCLOUD_ACCOUNT\"|" gdc-gcp-project/tf/terraform-gdc.auto.tfvars
  sed -i '' "s|^svc_account =.*|svc_account = \"$SA_EMAIL\"|" gdc-gcp-project/tf/terraform-gdc.auto.tfvars
  sed -i '' "s|^path_module =.*|path_module = \"$PWD\"|" gdc-gcp-project/tf/terraform-gdc.auto.tfvars
  sed -i '' "s|^orgid =.*|orgid = \"$ORG_ID\"|" gdc-gcp-project/tf/terraform-gdc.auto.tfvars
  sed -i '' "s|^gcp_region =.*|gcp_region = \"$GCP_REGION\"|" gdc-gcp-project/tf/terraform-gdc.auto.tfvars
  sed -i '' "s|^suffix =.*|suffix = \"$RANDOM_SUFFIX\"|" gdc-gcp-project/tf/terraform-gdc.auto.tfvars
else
  # This block runs on Linux and other OS
  sed -i "s|^gcp_orgid =.*|gcp_orgid = \"$ORG_ID\"|" terraform.tfvars
  sed -i "s|^gcp_project =.*|gcp_project = \"$PROJECT_ID\"|" terraform.tfvars
  sed -i "s|^gcp_region =.*|gcp_region = \"$GCP_REGION\"|" terraform.tfvars
  sed -i "s|^gcp_zone =.*|gcp_zone = \"$GCP_ZONE\"|" terraform.tfvars
  sed -i "s|^gcp_project_number =.*|gcp_project_number = \"$PROJECT_NUMBER\"|" terraform.tfvars
  sed -i "s|^gcp_project_folder_id =.*|gcp_project_folder_id = \"$FOLDER_ID\"|" terraform.tfvars
  sed -i "s|^user_account =.*|user_account = \"$GCLOUD_ACCOUNT\"|" terraform.tfvars
  sed -i "s|^svc_account =.*|svc_account = \"$SA_EMAIL\"|" terraform.tfvars
  sed -i "s|^path_module =.*|path_module = \"$PWD\"|" terraform.tfvars
  
  # Update GDC terraform.tfvars
  sed -i "s|^user_account =.*|user_account = \"$GCLOUD_ACCOUNT\"|" gdc-gcp-project/tf/terraform-gdc.auto.tfvars
  sed -i "s|^svc_account =.*|svc_account = \"$SA_EMAIL\"|" gdc-gcp-project/tf/terraform-gdc.auto.tfvars
  sed -i "s|^path_module =.*|path_module = \"$PWD\"|" gdc-gcp-project/tf/terraform-gdc.auto.tfvars
  sed -i "s|^orgid =.*|orgid = \"$ORG_ID\"|" gdc-gcp-project/tf/terraform-gdc.auto.tfvars
  sed -i "s|^gcp_region =.*|gcp_region = \"$GCP_REGION\"|" gdc-gcp-project/tf/terraform-gdc.auto.tfvars
  sed -i "s|^suffix =.*|suffix = \"$RANDOM_SUFFIX\"|" gdc-gcp-project/tf/terraform-gdc.auto.tfvars
fi

    printf "    ✅ \033[1;31m'terraform.tfvars'\033[0m updated with User specific configs.\n"
    printf "    ✅ \033[1;31m'gdc-gcp-project/tf/terraform-gdc.auto.tfvars'\033[0m updated with GDC project configs.\n"


    # Show content after reset
    #printf "\n    📄 \033[1;31m'New content of terraform.tfvars (Press Enter to continue)'\033[0m:\n"
    printf "\n    📄 \033[1;31m'New content of terraform.tfvars'\033[0m:\n"
    #read -r -p ""
    printf "    ────────────────────────────────────────\n"
    cat terraform.tfvars | sed 's/^/    /'
    printf "    ────────────────────────────────────────\n"
    
    
    # Show content after reset
    printf "\n    📄 \033[1;31m'New content of gdc-gcp-project/tf/terraform-gdc.auto.tfvars'\033[0m:\n"
    #printf "\n    📄 \033[1;31m'New content of gdc-gcp-project/tf/terraform-gdc.auto.tfvars (Press Enter to continue)'\033[0m:\n"
    #read -r -p ""
    printf "    ────────────────────────────────────────\n"
    cat gdc-gcp-project/tf/terraform-gdc.auto.tfvars | sed 's/^/    /'
    printf "    ────────────────────────────────────────\n"
    
  else
    printf "    ℹ️  Keeping existing variable values.\n"
    PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_NAME" --format="value(projectNumber)")
    printf '    ⚙️ GCP Configurations Summary :\n'
    printf '      💡 Project name is:   \033[1;31m%s\033[0m\n' "$PROJECT_NAME"
    printf '      💡 Project ID is:     \033[1;31m%s\033[0m\n' "$PROJECT_ID"
    printf '      💡 Project number is: \033[1;31m%s\033[0m\n' "$PROJECT_NUMBER"
    printf '      💡 Organization ID is: \033[1;31m%s\033[0m\n' "$ORG_ID"
    printf '      💡 Region: \033[1;31m%s\033[0m\n' "$GCP_REGION"
    printf '      💡 Zone: \033[1;31m%s\033[0m\n' "$GCP_ZONE"
# 
#     printf "\n    📄 Existing content of terraform.tfvars (Press Enter to continue):\n"
#     read -r -p ""
#     printf "    ────────────────────────────────────────\n"
#     cat terraform.tfvars | sed 's/^/    /'
#     printf "    ────────────────────────────────────────\n"
#     
#     
#     # Show content after reset
#     printf "\n    📄 Existing content of gdc-gcp-project/tf/terraform-gdc.auto.tfvars (Press Enter to continue):\n"
#     read -r -p ""
#     printf "    ────────────────────────────────────────\n"
#     cat gdc-gcp-project/tf/terraform-gdc.auto.tfvars | sed 's/^/    /'
#     printf "    ────────────────────────────────────────\n"


  fi





else
  printf "    ✅ No Terraform variable files detected.\n"

  printf '\n'
  printf "▶️ Press Enter to proceed with the next step: \033[1;32m'Populate variables into terraform variables file'\033[0m"
  read -r -p ""
  ##populate terraform.tfvars:
  #printf "🔄 Updating terraform.tfvars variables ...\n"
  # Configs summary:

  PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_NAME" --format="value(projectNumber)")
  printf '    ⚙️ GCP Configurations Summary :\n'
    printf '      💡 Project name is:   \033[1;31m%s\033[0m\n' "$PROJECT_NAME"
    printf '      💡 Project ID is:     \033[1;31m%s\033[0m\n' "$PROJECT_ID"
    printf '      💡 Project number is: \033[1;31m%s\033[0m\n' "$PROJECT_NUMBER"
    printf '      💡 Organization ID is: \033[1;31m%s\033[0m\n' "$ORG_ID"
    printf '      💡 Region: \033[1;31m%s\033[0m\n' "$GCP_REGION"
    printf '      💡 Zone: \033[1;31m%s\033[0m\n' "$GCP_ZONE"


  if [[ "$(uname -s)" == "Darwin" ]]; then
    # This block runs on macOS
    sed -i '' "s/^gcp_orgid =.*/gcp_orgid = \"$ORG_ID\"/" terraform.tfvars
    sed -i '' "s/^gcp_project =.*/gcp_project = \"$PROJECT_ID\"/" terraform.tfvars
    sed -i '' "s/^gcp_region =.*/gcp_region = \"$GCP_REGION\"/" terraform.tfvars
    sed -i '' "s/^gcp_zone =.*/gcp_zone = \"$GCP_ZONE\"/" terraform.tfvars
    sed -i '' "s/^gcp_project_number =.*/gcp_project_number = \"$PROJECT_NUMBER\"/" terraform.tfvars
    sed -i '' "s/^gcp_project_folder_id =.*/gcp_project_folder_id = \"$FOLDER_ID\"/" terraform.tfvars
    sed -i '' "s/^user_account =.*/user_account = \"$GCLOUD_ACCOUNT\"/" terraform.tfvars
    sed -i '' "s/^svc_account =.*/svc_account = \"$SA_EMAIL\"/" terraform.tfvars
    #sed -i '' "s/^path_module =.*/path_module = \"$PWD\"/" terraform.tfvars
    sed -i '' "s|^path_module =.*|path_module = \"$PWD\"|" terraform.tfvars
    
    # Update GDC terraform.tfvars
    sed -i '' "s/^user_account =.*/user_account = \"$GCLOUD_ACCOUNT\"/" gdc-gcp-project/tf/terraform-gdc.auto.tfvars
    sed -i '' "s/^svc_account =.*/svc_account = \"$SA_EMAIL\"/" gdc-gcp-project/tf/terraform-gdc.auto.tfvars
    sed -i '' "s|^path_module =.*|path_module = \"$PWD\"|" gdc-gcp-project/tf/terraform-gdc.auto.tfvars
    sed -i '' "s/^orgid =.*/orgid = \"$ORG_ID\"/" gdc-gcp-project/tf/terraform-gdc.auto.tfvars
    sed -i '' "s/^gcp_region =.*/gcp_region = \"$GCP_REGION\"/" gdc-gcp-project/tf/terraform-gdc.auto.tfvars
    sed -i '' "s/^suffix =.*/suffix = \"$RANDOM_SUFFIX\"/" gdc-gcp-project/tf/terraform-gdc.auto.tfvars
  else
    # This block runs on Linux and other OS
    sed -i "s/^gcp_orgid =.*/gcp_orgid = \"$ORG_ID\"/" terraform.tfvars
    sed -i "s/^gcp_project =.*/gcp_project = \"$PROJECT_ID\"/" terraform.tfvars
    sed -i "s/^gcp_region =.*/gcp_region = \"$GCP_REGION\"/" terraform.tfvars
    sed -i "s/^gcp_zone =.*/gcp_zone = \"$GCP_ZONE\"/" terraform.tfvars
    sed -i "s/^gcp_project_number =.*/gcp_project_number = \"$PROJECT_NUMBER\"/" terraform.tfvars
    sed -i "s/^gcp_project_folder_id =.*/gcp_project_folder_id = \"$FOLDER_ID\"/" terraform.tfvars
    sed -i "s/^user_account =.*/user_account = \"$GCLOUD_ACCOUNT\"/" terraform.tfvars
    sed -i "s/^svc_account =.*/svc_account = \"$SA_EMAIL\"/" terraform.tfvars
    sed -i "s/^path_module =.*/path_module = \"$PWD\"/" terraform.tfvars
    sed -i "s|^path_module =.*|path_module = \"$PWD\"|" terraform.tfvars
    
    # Update GDC terraform.tfvars
    sed -i "s/^user_account =.*/user_account = \"$GCLOUD_ACCOUNT\"/" gdc-gcp-project/tf/terraform-gdc.auto.tfvars
    sed -i "s/^svc_account =.*/svc_account = \"$SA_EMAIL\"/" gdc-gcp-project/tf/terraform-gdc.auto.tfvars
    sed -i "s|^path_module =.*|path_module = \"$PWD\"|" gdc-gcp-project/tf/terraform-gdc.auto.tfvars
    sed -i "s/^orgid =.*/orgid = \"$ORG_ID\"/" gdc-gcp-project/tf/terraform-gdc.auto.tfvars
    sed -i "s/^gcp_region =.*/gcp_region = \"$GCP_REGION\"/" gdc-gcp-project/tf/terraform-gdc.auto.tfvars
    sed -i "s/^suffix =.*/suffix = \"$RANDOM_SUFFIX\"/" gdc-gcp-project/tf/terraform-gdc.auto.tfvars
  fi
  printf "    ✅ \033[1;31m'terraform.tfvars'\033[0m updated with User specific configs.\n"
  printf "    ✅ \033[1;31m'gdc-gcp-project/tf/terraform-gdc.auto.tfvars'\033[0m updated with GDC project configs.\n"


  # Show content after reset
  printf "\n    📄 Newly created terraform.tfvars (Press Enter to continue):\n"
  read -r -p ""
  printf "    ────────────────────────────────────────\n"
  cat terraform.tfvars | sed 's/^/    /'
  printf "    ────────────────────────────────────────\n"
  
  
  # Show content after reset
  printf "\n    📄 Newly created gdc-gcp-project/tf/terraform-gdc.auto.tfvars (Press Enter to continue):\n"
  read -r -p ""
  printf "    ────────────────────────────────────────\n"
  cat gdc-gcp-project/tf/terraform-gdc.auto.tfvars | sed 's/^/    /'
  printf "    ────────────────────────────────────────\n"




fi













printf '\n'
printf '\n'
printf "▶️ Press Enter to proceed with the next step: \033[1;32m'Assets Storage Bucket'\033[0m"
read -r -p ""
## Enable storage api service for creating bucket
SERVICE_NAME="storage.googleapis.com"
printf "    🔄 Enabling \033[1;31m'${SERVICE_NAME}'\033[0m service API ...\n"

gcloud services enable $SERVICE_NAME --async --quiet > /dev/null 2>&1
while true; do
  # Check if the service is enabled.
  SERVICE_STATUS=$(gcloud services list --filter="NAME=$SERVICE_NAME" --format="value(state)")
  if [[ "$SERVICE_STATUS" == "ENABLED" ]]; then
    printf "    ✅ Service \033[1;31m'$SERVICE_NAME'\033[0m is now enabled.\n"
    break
  else
    printf "    ⏳ Still waiting for service to be enabled. Current status: '$SERVICE_STATUS'\n"
    sleep 1 # Wait for 5 seconds before checking again.
  fi
done


## Create bucket: ## propagation of billing linking to project takes time... check again on new test run.

printf "\n    🔄 Creating storage bucket: \033[1;31m'vdc-bucket-clone-${RANDOM_SUFFIX}'\033[0m"

BUCKET_NAME="vdc-${RANDOM_SUFFIX}-bucket-clone"

if gcloud storage buckets describe gs://${BUCKET_NAME} > /dev/null 2>&1; then
  printf "\n    ✅ Bucket \033[1;31m'gs://${BUCKET_NAME}'\033[0m already exists.\n"
else
  printf "\n    🔄 Creating storage bucket: \033[1;31m'gs://${BUCKET_NAME}'\033[0m"

  gcloud storage buckets create gs://${BUCKET_NAME} \
    --project=${PROJECT_ID} \
    --location=${GCP_REGION} \
    --uniform-bucket-level-access > /dev/null 2>&1

  while ! gcloud storage buckets describe gs://${BUCKET_NAME} > /dev/null 2>&1; do
    printf "\n    ⏳ Waiting for bucket to finish creating ...\n"
    sleep 1
  done
  printf "\n    ✅ Bucket \033[1;31m'gs://${BUCKET_NAME}'\033[0m ready.\n"
fi







































# ## Not needed: by default the GCE instances will have read/write to the local bucket. What was needed was for the user to hvae access to the rmemote bucket we clone content from. this is done with above mentionned message of making sure use is member of the google group.
# 
# ## Make user storage object admin
# printf "    🔄 Assigning user \033[1;31m'storage objectAdmin'\033[0m role: \n"
# GCE_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"
# 
# gcloud storage buckets add-iam-policy-binding gs://${BUCKET_NAME} \
#     --member="serviceAccount:${GCE_SA}" \
#     --role="roles/storage.objectAdmin" > /dev/null 2>&1
# 
# while true; do
#   # Get the IAM policy in a JSON format and redirect errors
#   POLICY_JSON=$(gcloud storage buckets get-iam-policy gs://${BUCKET_NAME} --format="json" 2> /dev/null)
#   
#   # Check if the policy contains the required role and member
#   if [[ $(echo "${POLICY_JSON}" | jq -r --arg ROLE "roles/storage.objectAdmin" --arg MEMBER "serviceAccount:${GCE_SA}" '.bindings[] | select(.role==$ROLE) | .members[] | select(.==$MEMBER)') == "serviceAccount:${GCE_SA}" ]]; then
#     printf "    ✅ \033[1;31m'storage.objectAdmin'\033[0m role has been assigned to the service account.\n"
#     break
#   else
#     printf "    ⏳ Still waiting for IAM policy to be applied..."
#     sleep 1 # Wait for 5 seconds before checking again
#   fi
# done
# 
















printf '\n'
printf "▶️ Press Enter to proceed with the next step: \033[1;32m'Clone lab assets to bucket'\033[0m"
read -r -p "Press Enter to start"
# ## Clone content of source assets bucket 
#printf "🔄 Cloning content of source asset bucket  to: \033[1;31m'${BUCKET_NAME}'\033[0m:\n"


# resource "null_resource" "bucket_cloning" {
#   triggers = {
#   # Re-run only if these values change.
#   # To force re-run on every apply, use something like: run_id = timestamp()
#   destination = google_storage_bucket.project_bucket.name
#   }
#   provisioner "local-exec" {
#     # This command will export the image to your local directory
#     command = "gsutil -m cp -r gs://vdc-tf-bucket/* gs://${google_storage_bucket.project_bucket.name}/"
#     interpreter = ["bash", "-c"]
#   }
# }
# Count the number of objects in the destination bucket
# Define the list of available buckets
BUCKETS_LIST=("vdc-tf-bucket")
#BUCKETS_LIST=("vdc-tf-bucket" "vdc-tf-bucket-jimit")

# Prompt the user to select a bucket
#printf "    ⚠️ Make sure your provide the lab admin your \033[1;32m'Argolis user/admin email address'\033[0m and your \033[1;32m'Argolis Google Workspace ID'\033[0m (Press Enter to Continue)"
















# printf "    📋 Please choose which bucket to clone from:\n"
# select BUCKET_CHOICE in "${BUCKETS_LIST[@]}"; do
#   if [[ -n "$BUCKET_CHOICE" ]]; then
#     SOURCE_BUCKET="$BUCKET_CHOICE"
#     printf "    ✅ Selected bucket: \033[1;31m${SOURCE_BUCKET}\033[0m\n"
#     break
#   else
#     printf "    ❌ Invalid choice. Please select a valid number.\n"
#   fi
# done
SOURCE_BUCKET="vdc-tf-bucket"

#Validating access to remote project
printf "    🔍 Validating read access to the source bucket...\n"
if ! gsutil ls "gs://${SOURCE_BUCKET}/" > /dev/null 2>&1; then
    printf "    ❌ ERROR: Failed to access source bucket \033[1;31m'${SOURCE_BUCKET}'\033[0m.\n"
    #printf "    👉 Make sure \033[1;31m'${GCLOUD_ACCOUNT}'\033[0m joined the google group \033[1;34m'vdc-assets-members@meillier.altostrat.com'\033[0m  @ \033[1;34m'https://groups.google.com/a/meillier.altostrat.com/g/vdc-assets-members'\033[0m and re-run main.sh.\n"
    printf "    ⚠️ Make sure your provide the lab admin your \033[1;32m'Argolis user/admin email address'\033[0m and your \033[1;32m'Argolis Google Workspace ID'\033[0m (Cancel and rerun)"   
fi
#printf "    ✅ Read access to source bucket validated for (\033[1;31m'${GCLOUD_ACCOUNT}'\033[0m member of google group \033[1;34m'https://groups.google.com/a/meillier.altostrat.com/g/vdc-assets-members'\033[0m ).\n"
printf "    ✅ Read access to source bucket validated for \033[1;31m'${GCLOUD_ACCOUNT}'\033[0m.\n"

OBJECT_COUNT=$(gsutil ls "gs://${BUCKET_NAME}/" 2>/dev/null | wc -l)

# Check if the object count is 0
if [[ "$OBJECT_COUNT" -eq 0 ]]; then
    echo "    ✅ Destination bucket is empty/new. Proceeding with copy:"
    # The copy command
    gsutil -m cp -r "gs://${SOURCE_BUCKET}/*" "gs://${BUCKET_NAME}/"
    printf "✅ Source lab Assets Cloning complete \n"

else
    printf "    ✅ Project bucket \033[1;31m'${BUCKET_NAME}'\033[0m already has the assets."
    # Optional: print the number of objects found
fi













############# / BEGIN COMMENTED OUT# during jimit tests 
# 
# #### YAN: vmmigration only needed if was to import compute image from a remote project image repository..... here we just create the image from our local bucket so don't need that...
# 
# 
# printf '\n'
# printf '\n'
# printf  "▶️ Press Enter to proceed with the next step: \033[1;32m'Enable service for the Import of GCE custom image and misc services'\033[0m"
# read -r -p ""
# #printf "🔄 Importing custom GCE image to project:\n"
# 
# 
# # #Setup target project: enable services - https://cloud.google.com/migrate/virtual-machines/docs/5.0/get-started/target-project#identify
# # 
# # resource "google_project_service" "vmmigration_api" {
# #   project            = local.gcp-project
# #   service            = "vmmigration.googleapis.com"
# #   disable_on_destroy = false # Set to true to disable on destroy
# # }
# 
# 
# 
# SERVICE_NAME="vmmigration.googleapis.com"
# #printf "🔄 Enabling \033[1;31m'${SERVICE_NAME}'\033[0m API ...\n"
# printf "    ⏳ Enabling service \033[1;31m'${SERVICE_NAME}'\033[0m\n"
# gcloud services enable "${SERVICE_NAME}" --async > /dev/null 2>&1
# 
# while true; do
#   SERVICE_STATUS=$(gcloud services list --filter="config.name:${SERVICE_NAME}" --format="value(STATE)")
#   
#   if [[ "${SERVICE_STATUS}" == "ENABLED" ]]; then
#     printf "    ✅ Service is enabled.\n"
#     break
#   else
#     printf "    ⏳ Waiting for service to finish being enabled...\n"
#     sleep 1
#   fi
# done
# 
# 
# 
# #Adding a target assigns the Migrate to Virtual Machines default service account, service-${PROJECT_NUMER}@gcp-sa-vmmigration.iam.gserviceaccount.com, the required service role on the target project.
# TARGET_PROJECT_COUNT=$(gcloud alpha migration vms target-projects list --format="value(${PROJECT_ID})" | wc -l)
# 
# while [[ "$TARGET_PROJECT_COUNT" -eq 0 ]]; do
#     printf "\n    🚨🚨 👉 Add \033[1;31m'${PROJECT_ID}'\033[0m as target project @ \033[1;34m'https://console.cloud.google.com/compute/mfce/dashboard?project=${PROJECT_ID}'\033[0m\n"
#     read -r -p "    ▶️ Press Enter to continue..."
#     # Re-evaluate the condition by getting an updated count
#     TARGET_PROJECT_COUNT=$(gcloud alpha migration vms target-projects list --format="value(TARGET_PROJECT)" | wc -l)
# done
# 
############# / END COMMENTED OUT


# resource "google_project_service" "svcmgmt_api" {
#   project            = local.gcp-project
#   service            = "servicemanagement.googleapis.com"
#   disable_on_destroy = false # Set to true to disable on destroy
# }

SERVICE_NAME="servicemanagement.googleapis.com"
printf "\n    🔄 Enabling \033[1;31m'${SERVICE_NAME}'\033[0m service API ...\n"
gcloud services enable $SERVICE_NAME --async --quiet > /dev/null 2>&1
while true; do
  # Check if the service is enabled.
  SERVICE_STATUS=$(gcloud services list --filter="NAME=$SERVICE_NAME" --format="value(state)")
  if [[ "$SERVICE_STATUS" == "ENABLED" ]]; then
    printf "    ✅ Service \033[1;31m'$SERVICE_NAME'\033[0m is now enabled.\n"
    break
  else
    printf "      ⏳ Still waiting for service to be enabled. Current status: '$SERVICE_STATUS'\n"
    sleep 1 # Wait for 5 seconds before checking again.
  fi
done


# resource "google_project_service" "svctrl_api" {
#   project            = local.gcp-project
#   service            = "servicecontrol.googleapis.com"
#   disable_on_destroy = false # Set to true to disable on destroy
# }

SERVICE_NAME="servicecontrol.googleapis.com"
printf "\n    🔄 Enabling \033[1;31m'${SERVICE_NAME}'\033[0m service API ...\n"
gcloud services enable $SERVICE_NAME --async --quiet > /dev/null 2>&1
while true; do
  # Check if the service is enabled.
  SERVICE_STATUS=$(gcloud services list --filter="NAME=$SERVICE_NAME" --format="value(state)")
  if [[ "$SERVICE_STATUS" == "ENABLED" ]]; then
    printf "    ✅ Service \033[1;31m'$SERVICE_NAME'\033[0m is now enabled.\n"
    break
  else
    printf "      ⏳ Still waiting for service to be enabled. Current status: '$SERVICE_STATUS'\n"
    sleep 1 # Wait for 5 seconds before checking again.
  fi
done



# resource "google_project_service" "iam_api" {
#   project            = local.gcp-project
#   service            = "iam.googleapis.com"
#   disable_on_destroy = false # Set to true to disable on destroy
# }
SERVICE_NAME="iam.googleapis.com"
printf "\n    🔄 Enabling \033[1;31m'${SERVICE_NAME}'\033[0m service API ...\n"
gcloud services enable $SERVICE_NAME --async --quiet > /dev/null 2>&1
while true; do
  # Check if the service is enabled.
  SERVICE_STATUS=$(gcloud services list --filter="NAME=$SERVICE_NAME" --format="value(state)")
  if [[ "$SERVICE_STATUS" == "ENABLED" ]]; then
    printf "    ✅ Service \033[1;31m'$SERVICE_NAME'\033[0m is now enabled.\n"
    break
  else
    printf "      ⏳ Still waiting for service to be enabled. Current status: '$SERVICE_STATUS'\n"
    sleep 1 # Wait for 5 seconds before checking again.
  fi
done

SERVICE_NAME="cloudbilling.googleapis.com"
printf "\n    🔄 Enabling \033[1;31m'${SERVICE_NAME}'\033[0m service API ...\n"
gcloud services enable $SERVICE_NAME --async --quiet > /dev/null 2>&1
while true; do
  # Check if the service is enabled.
  SERVICE_STATUS=$(gcloud services list --filter="NAME=$SERVICE_NAME" --format="value(state)")
  if [[ "$SERVICE_STATUS" == "ENABLED" ]]; then
    printf "    ✅ Service \033[1;31m'$SERVICE_NAME'\033[0m is now enabled.\n"
    break
  else
    printf "      ⏳ Still waiting for service to be enabled. Current status: '$SERVICE_STATUS'\n"
    sleep 1 # Wait for 5 seconds before checking again.
  fi
done









# resource "google_project_iam_member" "vmmigration_sa_storageviewer" {
#   project = local.gcp-project
#   role    = "roles/storage.objectViewer"
#   member  = "serviceAccount:service-${local.gcp-project-number}@gcp-sa-vmmigration.iam.gserviceaccount.com"
# }

# SA="service-${PROJECT_NUMBER}@gcp-sa-vmmigration.iam.gserviceaccount.com"
# ROLE="roles/storage.objectViewer"
# 
# printf "\n    🔄 Granting \033[1;31m'${ROLE}'\033[0m to \033[1;31m'${SA}'\033[0m ..."
# gcloud projects add-iam-policy-binding ${PROJECT_ID} \
#     --member="serviceAccount:${SA}" \
#     --role="${ROLE}" > /dev/null 2>&1
# while true; do
#   # Get the project's IAM policy and filter for the specific role and member
#   POLICY_JSON=$(gcloud projects get-iam-policy ${PROJECT_ID} --format="json" 2> /dev/null)
#   
#   # Use jq to check if the member exists in the bindings for the specified role
#   if [[ $(echo "${POLICY_JSON}" | jq -r --arg ROLE "${ROLE}" --arg MEMBER "serviceAccount:${SA}" '.bindings[] | select(.role==$ROLE) | .members[] | select(.==$MEMBER)') == "serviceAccount:${SA}" ]]; then
#     echo "    ✅ IAM role ${ROLE} is now applied to \033[1;31m'${SA}'\033[0m."
#     break
#   else
#     echo "      ⏳ Still waiting for the policy to finish being applied ..."
#     sleep 1
#   fi
# done

# resource "google_project_iam_member" "user_vmmigrationadmin" {
#   project = local.gcp-project
#   role    = "roles/vmmigration.admin"
#   member  = "user:${local.user-account}"
# }





# 
# ########## BEING  COMMENT OUT Jimmit
# 
# ROLE="roles/vmmigration.admin"
# printf "\n    🔄 Granting \033[1;31m'${ROLE}'\033[0m to \033[1;31m'${GCLOUD_ACCOUNT}'\033[0m ..."
# 
# gcloud projects add-iam-policy-binding ${PROJECT_ID} \
#     --member="user:${GCLOUD_ACCOUNT}" \
#     --role="${ROLE}" > /dev/null 2>&1
# while true; do
#   # Get the project's IAM policy and filter for the specific role and member
#   POLICY_JSON=$(gcloud projects get-iam-policy ${PROJECT_ID} --format="json" 2> /dev/null)
#   
#   # Use jq to check if the member exists in the bindings for the specified role
#   if [[ $(echo "${POLICY_JSON}" | jq -r --arg ROLE "${ROLE}" --arg MEMBER "user:${GCLOUD_ACCOUNT}" '.bindings[] | select(.role==$ROLE) | .members[] | select(.==$MEMBER)') == "user:${GCLOUD_ACCOUNT}" ]]; then
#     printf "\n    ✅ IAM role \033[1;31m'${ROLE}'\033[0m has been granted to \033[1;31m'${GCLOUD_ACCOUNT}'\033[0m."
#     break
#   else
#     printf "\n      ⏳ Still waiting for the policy to finish being applied ..."
#     sleep 1
#   fi
# done
# 
# 
# 
# 
# 
# # resource "google_project_iam_member" "vmmigration_sa_vmmigrationagent" {
# #   project = local.gcp-project
# #   role    = "roles/vmmigration.serviceAgent"
# #   member  = "serviceAccount:service-${local.gcp-project-number}@gcp-sa-vmmigration.iam.gserviceaccount.com"
# # }
# 
# SA="service-${PROJECT_NUMBER}@gcp-sa-vmmigration.iam.gserviceaccount.com"
# ROLE="roles/vmmigration.serviceAgent"
# printf '\n'
# printf "\n    🔄 Granting \033[1;31m'${ROLE}'\033[0m to \033[1;31m'${SA}'\033[0m ..."
# gcloud projects add-iam-policy-binding ${PROJECT_ID} \
#     --member="serviceAccount:${SA}" \
#     --role="${ROLE}" > /dev/null 2>&1
# while true; do
#   # Get the project's IAM policy and filter for the specific role and member
#   POLICY_JSON=$(gcloud projects get-iam-policy ${PROJECT_ID} --format="json" 2> /dev/null)
#   
#   # Use jq to check if the member exists in the bindings for the specified role
#   if [[ $(echo "${POLICY_JSON}" | jq -r --arg ROLE "${ROLE}" --arg MEMBER "serviceAccount:${SA}" '.bindings[] | select(.role==$ROLE) | .members[] | select(.==$MEMBER)') == "serviceAccount:${SA}" ]]; then
#     printf "\n    ✅ IAM role ${ROLE} is now applied to \033[1;31m'${SA}'\033[0m."
#     break
#   else
#     printf "\n      ⏳ Still waiting for the policy to finish being applied ..."
#     sleep 1
#   fi
# done
# printf '\n'
# 
# 
# 
# 
# 
# # resource "null_resource" "vmdk_bucket_image_import_pnetlab_v5_custom" {
# #   # This provisioner has to wait for all necessary permissions to be set.
# #   # The `local-exec` will not run until the dependencies are met.
# #   # https://cloud.google.com/migrate/virtual-machines/docs/5.0/migrate/image_import#image_import_process
# #   depends_on = [
# #     google_project_iam_member.vmmigration_sa_vmmigrationagent,
# #     google_project_iam_member.user_vmmigrationadmin,
# #     google_project_iam_member.vmmigration_sa_storageviewer
# #   ]
# # 
# #   provisioner "local-exec" {
# #     ##gcloud migration vms image-imports create pnetlab-v5-custom-base-imported --source-file="gs://vdc-tf-clone/assets-pnetlab/custom-images/pnetlab/pnetlab-v5-custom-base.vmdk" --location=us-central1 --family-name=vdc-pnetlab-images --target-project=vdc-tf2
# #     command = <<EOT
# #     gcloud migration vms image-imports create pnetlab-v5-custom-base-imported \
# #     --source-file=gs://${google_storage_bucket.project_bucket.name}/assets-pnetlab/custom-images/pnetlab/pnetlab-v5-custom-base.vmdk \
# #     --location=${local.gcp-region} \
# #     --family-name=vdc-pnetlab-images \
# #     --target-project=${local.gcp-project}
# #     EOT
# #   }
# # }
# # # ## check status with:
# # # gcloud compute images list | grep v5
# # # gcloud migration vms image-imports list --location us-central1
# 
# 
# 
# 
########### /END jimmit

















IMAGE_NAME="vdc-pnetlab-v5-imported"
IMAGE_STATUS=$(gcloud compute images list --filter="name=${IMAGE_NAME}" --format="value(status)" 2>/dev/null)

if [[ "$IMAGE_STATUS" != "READY" ]]; then
printf '\n'
printf "▶️ Press Enter to proceed with the next step: \033[1;32m'Import Compute image'\033[0m (ETA ~10 minutes)"
read -r -p ""

# Get list of available images from the bucket
printf "    🔍 Scanning bucket for available PNetLab images...\n"
BUCKET_PATH="gs://${BUCKET_NAME}/assets-pnetlab/custom-images/pnetlab/"

# Check if bucket path exists and is accessible
if ! gsutil ls "${BUCKET_PATH}" > /dev/null 2>&1; then
  printf "    ❌ ERROR: Cannot access bucket path \033[1;31m'${BUCKET_PATH}'\033[0m\n"
  printf "    👉 Please verify the bucket exists and you have proper permissions.\n"
  exit 1
fi

# Get list of image files (tar.gz, vmdk, img extensions)
AVAILABLE_IMAGES=($(gsutil ls "${BUCKET_PATH}" | grep -E '\.(tar\.gz|vmdk|img)$' | xargs -n1 basename 2>/dev/null))

# Check if any images were found
if [ ${#AVAILABLE_IMAGES[@]} -eq 0 ]; then
  printf "    ❌ ERROR: No image files found in \033[1;31m'${BUCKET_PATH}'\033[0m\n"
  printf "    👉 Please verify the bucket contains image files with extensions: .tar.gz, .vmdk, or .img\n"
  exit 1
fi

# Display available images
printf "    📋 Please choose which PNetLab image to deploy (deploy latest: \033[1;31mv12\033[0m):\n"
for i in "${!AVAILABLE_IMAGES[@]}"; do
  printf "      $((i+1))) \033[1;31m${AVAILABLE_IMAGES[i]}\033[0m\n"
done
printf '\n'

# Get user selection with validation
while true; do
  read -p "    👉 Enter your choice (1-${#AVAILABLE_IMAGES[@]}): " choice
  
  # Validate input is a number
  if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#AVAILABLE_IMAGES[@]}" ]; then
    SOURCE_IMAGE="${AVAILABLE_IMAGES[$((choice-1))]}"
    IMAGE_DESCRIPTION="PNetLab image: ${SOURCE_IMAGE}"
    break
  else
    printf "    ❌ Invalid choice. Please enter a number between 1 and ${#AVAILABLE_IMAGES[@]}.\n"
  fi
done

printf "        ✅ Selected image: \033[1;31m${SOURCE_IMAGE}\033[0m\n"
printf "\n"
printf "    👉 Press Enter to proceed with image import"
read -r -p ""
#printf "\n"

IMAGE_NAME="vdc-pnetlab-v5-imported"
IMAGE_STATUS=$(gcloud compute images list --filter="name=${IMAGE_NAME}" --format="value(status)" 2>/dev/null)

if [[ "$IMAGE_STATUS" != "READY" ]]; then

  printf "        🔄 Starting \033[1;31m'${SOURCE_IMAGE}'\033[0m compute image creation in background as \033[1;31m'${IMAGE_NAME}'\033[0m...\n"
  
  # Start gcloud command in background with output suppressed
  nohup gcloud compute images create ${IMAGE_NAME} \
  --source-uri="gs://${BUCKET_NAME}/assets-pnetlab/custom-images/pnetlab/${SOURCE_IMAGE}" \
  --project=${PROJECT_NAME} \
  --family=vdc-pnetlab-images \
  --description="${IMAGE_DESCRIPTION} - Source: ${SOURCE_IMAGE}" \
  --guest-os-features=UEFI_COMPATIBLE \
  --licenses="https://www.googleapis.com/compute/v1/projects/ubuntu-os-pro-cloud/global/licenses/ubuntu-pro-1804-lts","https://www.googleapis.com/compute/v1/projects/vm-options/global/licenses/enable-vmx" > /dev/null 2>&1 &



  # Capture the background process ID
  GCLOUD_PID=$!
  
  IMAGE_STATUS=""
  ELAPSED_SECONDS=0

  printf "        ⏳ Image creation started in the background (PID: $GCLOUD_PID). Monitoring progress...\n"

  while [[ "$IMAGE_STATUS" != "READY" ]]; do
    # Check if background process is still running
    if ! kill -0 $GCLOUD_PID 2>/dev/null; then
      # Process finished, check if it was successful
      wait $GCLOUD_PID
      EXIT_CODE=$?
      if [[ $EXIT_CODE -ne 0 ]]; then
        printf "          ❌ Image creation command failed with exit code $EXIT_CODE.\n"
        exit 1
      fi
    fi
    
    # Get the status of the image
    IMAGE_STATUS=$(gcloud compute images list --filter="name=${IMAGE_NAME}" --format="value(status)" 2>/dev/null)

    if [[ -z "$IMAGE_STATUS" ]]; then
      printf "          🔍 Still waiting for image to appear in the list (%d seconds elapsed)...\n" "$ELAPSED_SECONDS"
    elif [[ "$IMAGE_STATUS" == "FAILED" ]]; then
      printf "          ❌ Image creation failed. Status is 'FAILED'.\n"
      # Kill the background process if still running
      kill $GCLOUD_PID 2>/dev/null
      exit 1
    else
      printf "          ⏳ Image creation in progress. Current status: '\033[1;33m${IMAGE_STATUS}\033[0m' (%d seconds/~600s)\n" "$ELAPSED_SECONDS"
    fi
    sleep 5
    ELAPSED_SECONDS=$((ELAPSED_SECONDS + 5))
  done

  printf "        ✅ Image \033[1;31m'${IMAGE_NAME}'\033[0m is now ready.\n"
else
  printf "        ✅ Image \033[1;31m'${IMAGE_NAME}'\033[0m already exists in project.\n"
fi

echo "Image used for pnet: ${SOURCE_IMAGE} from storage bucket" > ./main-info/pnet_image_sourced.txt
fi


# 
# # Sanitize the source image name to create a valid GCE image name
# # 1. Remove file extensions like .tar.gz, .vmdk, etc.
# if [[ $SOURCE_IMAGE == *.tar.gz ]]; then
#   CLONED_IMAGE_NAME_BASE="${SOURCE_IMAGE%.tar.gz}"
# else
#   CLONED_IMAGE_NAME_BASE="${SOURCE_IMAGE%%.*}"
# fi
# # 2. Replace invalid characters (like dots or underscores) with hyphens and convert to lowercase
# CLONED_IMAGE_NAME_SANITIZED=$(echo "$CLONED_IMAGE_NAME_BASE" | tr '._' '-' | tr '[:upper:]' '[:lower:]')
# # 3. Ensure it starts with a letter
# if [[ ! $CLONED_IMAGE_NAME_SANITIZED =~ ^[a-z] ]]; then
#   CLONED_IMAGE_NAME_SANITIZED="image-${CLONED_IMAGE_NAME_SANITIZED}"
# fi
# # 4. Truncate to 63 characters
# CLONED_IMAGE_NAME=$(echo "${CLONED_IMAGE_NAME_SANITIZED}" | cut -c 1-63)
# 
# printf "        ℹ️ Sanitized clone name is: \033[1;31m'${CLONED_IMAGE_NAME}'\033[0m\n"
# CLONED_IMAGE_STATUS=$(gcloud compute images list --filter="name=${CLONED_IMAGE_NAME}" --format="value(status)" 2>/dev/null)
# 
# if [[ "$CLONED_IMAGE_STATUS" != "READY" ]]; then
#   printf "        🔄 Starting to clone image \033[1;31m'${IMAGE_NAME}'\033[0m to \033[1;31m'${CLONED_IMAGE_NAME}'\033[0m...\n"
#   
#   nohup gcloud compute images create ${CLONED_IMAGE_NAME} \
#   --source-image=${IMAGE_NAME} \
#   --project=${PROJECT_NAME} \
#   --family=vdc-pnetlab-images \
#   --description="Cloned from ${IMAGE_NAME}" > /dev/null 2>&1 &
# 
#   GCLOUD_PID=$!
#   
#   CLONED_IMAGE_STATUS=""
#   ELAPSED_SECONDS=0
# 
#   printf "        ⏳ Image cloning started in the background (PID: $GCLOUD_PID). Monitoring progress...\n"
# 
#   while [[ "$CLONED_IMAGE_STATUS" != "READY" ]]; do
#     if ! kill -0 $GCLOUD_PID 2>/dev/null; then
#       wait $GCLOUD_PID
#       EXIT_CODE=$?
#       if [[ $EXIT_CODE -ne 0 ]]; then
#         printf "          ❌ Image cloning command failed with exit code $EXIT_CODE.\n"
#         exit 1
#       fi
#     fi
#     
#     CLONED_IMAGE_STATUS=$(gcloud compute images list --filter="name=${CLONED_IMAGE_NAME}" --format="value(status)" 2>/dev/null)
# 
#     if [[ -z "$CLONED_IMAGE_STATUS" ]]; then
#       printf "          🔍 Still waiting for cloned image to appear in the list (%d seconds elapsed)...\n" "$ELAPSED_SECONDS"
#     elif [[ "$CLONED_IMAGE_STATUS" == "FAILED" ]]; then
#       printf "          ❌ Image cloning failed. Status is 'FAILED'.\n"
#       kill $GCLOUD_PID 2>/dev/null
#       exit 1
#     else
#       printf "          ⏳ Image cloning in progress. Current status: '\033[1;33m${CLONED_IMAGE_STATUS}\033[0m' (%d seconds elapsed)\n" "$ELAPSED_SECONDS"
#     fi
#     sleep 5
#     ELAPSED_SECONDS=$((ELAPSED_SECONDS + 5))
#   done
# 
#   printf "        ✅ Cloned image \033[1;31m'${CLONED_IMAGE_NAME}'\033[0m is now ready.\n"
# else
#   printf "        ✅ Cloned image \033[1;31m'${CLONED_IMAGE_NAME}'\033[0m already exists in project.\n"
# fi


















# 
# printf '\n'
# printf "▶️ Press Enter to proceed with the next step: \033[1;32m'Configure Jump host Remote Desktop Access Credentials'\033[0m"
# read -r -p ""
# #printf "🔄 Configuring Jump host chrome remote desktop access credentials:"
# 


# ## Creates 'crd-sysprep-script.ps1' script needed for windows jump host startup script.
 
# # 1/ Manually: Update crd-auth-command.txt with your content obtained from  https://remotedesktop.google.com/headless
#     ## https://cloud.google.com/architecture/chrome-desktop-remote-windows-compute-engine#copy-startup-command
# 
# Clean up any existing CRD auth file to ensure fresh credentials are requested
if [[ -f "${WORKING_DIR}/assets-jump-host/crd-auth-command.txt" ]]; then
    printf "    🧹 Removing existing CRD auth file to ensure fresh credentials...\n"
    rm "${WORKING_DIR}/assets-jump-host/crd-auth-command.txt"
fi

# Create a temporary auth file from the dummy file for the initial Terraform apply
printf "    ℹ️ Creating temporary CRD auth file for initial deployment...\n"
cp "${WORKING_DIR}/assets-jump-host/crd-auth-command-dummy.txt" "${WORKING_DIR}/assets-jump-host/crd-auth-command.txt"

# Check for saved auth file first (legacy support)
if [[ -f "${WORKING_DIR}/assets-jump-host/saved_crd-auth-command.txt" ]]; then
    AUTH_FILE="${WORKING_DIR}/assets-jump-host/saved_crd-auth-command.txt"
    printf "    ✅ Using saved CRD auth command from \033[1;31m'$AUTH_FILE'\033[0m\n"
else
    # Use dummy/template file for initial deployment
    AUTH_FILE="${WORKING_DIR}/assets-jump-host/crd-auth-command-dummy.txt"
fi

# Use AUTH_FILE content for initial deployment
if [[ -f "$AUTH_FILE" ]]; then
    crd_auth_command=$(cat "$AUTH_FILE")
    printf "    ✅ Using template CRD auth command from \033[1;31m'$AUTH_FILE'\033[0m for initial deployment\n"
else
    printf "    ❌ ERROR: Template AUTH_FILE not found at \033[1;31m'$AUTH_FILE'\033[0m\n"
    printf "    👉 Please ensure the template/dummy crd-auth-command-dummy.txt file exists in '${WORKING_DIR}/assets-jump-host/'.\n"
    exit 1
fi

# 2/ Generate powershell startup script: crd-sysprep-script.ps1 using get_crd_auth.sh and the content of crd-auth-command.txt as input (#https://cloud.google.com/architecture/chrome-desktop-remote-windows-compute-engine#create_the_startup_script)

chmod +x "${WORKING_DIR}/assets-jump-host/scripts/get_crd_auth.sh"
chmod +x ${WORKING_DIR}/assets-jump-host/scripts/sysprep.sh

#. ${WORKING_DIR}/assets-jump-host/scripts/get_crd_auth.sh < ${WORKING_DIR}/assets-jump-host/crd-auth-command.txt
. ${WORKING_DIR}/assets-jump-host/scripts/sysprep.sh
 
mv ${WORKING_DIR}/crd-sysprep-script.ps1 ${WORKING_DIR}/assets-jump-host/crd-sysprep-script.ps1
cat ${WORKING_DIR}/assets-jump-host/scripts/append-script.ps1 >> ${WORKING_DIR}/assets-jump-host/crd-sysprep-script.ps1


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



if [[ "$(uname -s)" == "Darwin" ]]; then
  # This block runs on macOS
  sed -i '' '/Write-Host "Password for user '\''admin'\'' has been updated."/r add_to_group.ps1' "${WORKING_DIR}/assets-jump-host/crd-sysprep-script.ps1"
elif [[ "$(uname -s)" == "Linux" ]]; then
  # This block runs on Linux and other OS
  sed -i '/Write-Host "Password for user '\''admin'\'' has been updated."/r add_to_group.ps1' "${WORKING_DIR}/assets-jump-host/crd-sysprep-script.ps1"
else
 printf "OS not Darwin or Linux. Need to make sure sed command worked. Check "${WORKING_DIR}/assets-jump-host/crd-sysprep-script.ps1" before continuing (hit Enter)"
  read -r -p ""
fi

rm add_to_group.ps1

cat << 'EOF' >> ${WORKING_DIR}/assets-jump-host/crd-sysprep-script.ps1

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

#printf "    ✅ Chrome Remote Desktop configuration script created.\n"

































## Check current version of terraform and install if needed:
printf '\n'
printf "▶️ Press Enter to proceed with the next step: \033[1;32m'Terraform version check'\033[0m"
read -r -p ""
#printf "🔄 Checking Terraform version...\n"

#!/bin/bash

if command -v terraform &> /dev/null; then
    printf "Terraform is \033[1;33m'already installed'\033[0m. Current version:\n"
    terraform version
else
    printf "Terraform \033[1;33m'not installed'\033[0m.\n"
fi

#read -p "▶️ Do you want to check for and install/upgrade Terraform? (y/n) " -n 1 -r
read -p $'▶️ Do you want to check for and install/upgrade Terraform? (\033[1;31my/n\033[0m) ' -n 1 -r
echo # Move to a new line

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Proceeding with Terraform installation/upgrade check..."

    # Check the OS and perform the correct action
    case "$(uname -s)" in
        "Darwin")
            echo "OS is macOS (Darwin). Starting manual installation/upgrade."
            # Your macOS installation code here
            TERRAFORM_VERSION="1.13.1"
            TERRAFORM_ARCH="arm64"
            DOWNLOAD_URL="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_darwin_${TERRAFORM_ARCH}.zip"
            DOWNLOAD_DIR="/tmp/terraform-install"
            INSTALL_PATH="/usr/local/bin"
            
            echo "Starting manual installation of Terraform version ${TERRAFORM_VERSION}..."
            echo "Creating temporary directory: ${DOWNLOAD_DIR}"
            mkdir -p "${DOWNLOAD_DIR}"
            cd "${DOWNLOAD_DIR}"
            
            echo "Downloading Terraform from ${DOWNLOAD_URL}"
            curl -sL -o "terraform.zip" "${DOWNLOAD_URL}"
            
            if [ ! -f "terraform.zip" ]; then
                echo "Error: Download failed."
                
            fi
            
            echo "Unzipping the archive..."
            unzip -q "terraform.zip"
            
            echo "Moving 'terraform' to ${INSTALL_PATH}"
            sudo mv terraform "${INSTALL_PATH}/"
            
            echo "Cleaning up temporary files..."
            cd ~
            rm -rf "${DOWNLOAD_DIR}"
            
            echo "Verifying installation..."
            if [ -x "${INSTALL_PATH}/terraform" ]; then
                echo "Terraform has been installed/upgraded successfully! ✅"
                terraform version
            else
                echo "Error: Terraform was not found."
                
            fi
            ;;
        "Linux")
            echo "OS is Linux. Upgrading via package manager."
            # Your Linux installation code here
            read -r -p "▶️ Press Enter to proceed with the Terraform installation/upgrade or Ctrl+C to abort."
            wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
            sudo apt update && sudo apt install -y terraform
            ;;
        *)
            printf "⚠️ Unsupported OS: $(uname -s). Please install Terraform manually.\n"
            ;;
    esac
else
    echo "Skipping Terraform installation/upgrade."
fi


#rm .terraform.lock.hcl
#terraform init
#approve SANTA rule if running on local workstation.



printf '\n'
printf "▶️ Press Enter to proceed with the next step: \033[1;32m'Terraform init check'\033[0m"
read -r -p ""
GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[33m'
NO_COLOR='\033[0m'
# Check for the presence of the .terraform directory, which indicates initialization
if [ -d ".terraform" ]; then
    echo -e "${GREEN}    ✅ Terraform is already initialized in the current directory.${NO_COLOR}"
else
    echo -e "${YELLOW}    ⚠️ Terraform has not been initialized in the current directory.${NO_COLOR}"
    # Prompt the user for action
    read -r -p $'    👉 Do you want to run "terraform init" now? (\033[1;31my/n\033[0m): ' response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}Initializing Terraform...${NO_COLOR}"
        terraform init
        
        # Check the exit status of terraform init
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}     ✅ Terraform successfully initialized.${NO_COLOR}"
        else
            echo -e "${RED}    ❌ Terraform initialization failed. Please check the output above.${NO_COLOR}"
            while true; do
              printf '🔄 Waiting for you to cancel execution of the script to review ... (Ctrl+C to exit)\n'
              sleep 5
            done

        fi
    else
        echo -e "${YELLOW}    🚨 Aborting: Terraform initialization skipped by user.${NO_COLOR}"

    fi
fi


printf '\n'
printf "▶️ Press Enter to proceed with the next step: \033[1;32m'Terraform init check of /servers/tf/'\033[0m"
read -r -p ""
GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[33m'
NO_COLOR='\033[0m'
# Check for the presence of the .terraform directory, which indicates initialization
cd $SCRIPT_DIR/servers/tf/
if [ -d ".terraform" ]; then
    echo -e "${GREEN}    ✅ Terraform is already initialized in servers/tf/.${NO_COLOR}"
else
    echo -e "${YELLOW}    ⚠️ Terraform has not been initialized in servers/tf/.${NO_COLOR}"
    
    # Prompt the user for action
    read -r -p $'    👉 Do you want to run \033[1;32m"terraform init"\033[0m now? (\033[1;31my/n\033[0m): ' response

    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}Initializing Terraform...${NO_COLOR}"
        terraform init
        
        # Check the exit status of terraform init
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}     ✅ Terraform successfully initialized in servers/tf/.${NO_COLOR}"
        else
            echo -e "${RED}    ❌ Terraform initialization failed. Please check the output above.${NO_COLOR}"
            while true; do
              printf '🔄 Waiting for you to cancel execution of the script to review ... (Ctrl+C to exit)\n'
              sleep 5
            done

        fi
    else
        echo -e "${YELLOW}    🚨 Aborting: Terraform initialization skipped by user.${NO_COLOR}"

    fi
fi


printf '\n'
printf "▶️ Press Enter to proceed with the next step: \033[1;32m'Terraform init check of /gdc-gcp-project/tf/'\033[0m"
read -r -p ""
GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[33m'
NO_COLOR='\033[0m'
# Check for the presence of the .terraform directory, which indicates initialization
cd $SCRIPT_DIR/gdc-gcp-project/tf
if [ -d ".terraform" ]; then
    echo -e "${GREEN}    ✅ Terraform is already initialized in /gdc-gcp-project/tf/.${NO_COLOR}"
else
    echo -e "${YELLOW}    ⚠️ Terraform has not been initialized in /gdc-gcp-project/tf/.${NO_COLOR}"
    
    # Prompt the user for action
    read -r -p $'    👉 Do you want to run "terraform init" now? (\033[1;31my/n\033[0m): ' response

    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}Initializing Terraform...${NO_COLOR}"
        terraform init
        
        # Check the exit status of terraform init
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}     ✅ Terraform successfully initialized in /gdc-gcp-project/tf/.${NO_COLOR}"
        else
            echo -e "${RED}    ❌ Terraform initialization failed. Please check the output above.${NO_COLOR}"
            while true; do
              printf '🔄 Waiting for you to cancel execution of the script to review ... (Ctrl+C to exit)\n'
              sleep 5
            done

        fi
    else
        echo -e "${YELLOW}    🚨 Aborting: Terraform initialization skipped by user.${NO_COLOR}"

    fi
fi

cd $SCRIPT_DIR

printf '\n'
printf '\n'
printf "✅ Terraform prerequisites complete.  running \033[1;33m'terraform apply'\033[0m.\n"



## Check current version of terraform and install if needed:
printf '\n'
printf "▶️ Press Enter to proceed with the infrastructure's \033[1;32m'Terraform apply'\033[0m"
read -r -p ""




printf "    🔄 Running \033[1;33m'terraform apply'\033[0m ...\n"

# Activate the Service Account just before it's needed by Terraform
printf "    🔐 Activating Service Account for Terraform...\n"
export GOOGLE_APPLICATION_CREDENTIALS="$KEY_FILE"
gcloud auth activate-service-account --key-file="$KEY_FILE" --project="$PROJECT_ID" #--quiet
printf "    ✅ Authentication switched to Service Account: \033[1;32m'${SA_EMAIL}'\033[0m\n"

# Re-export the credentials one last time as a safeguard for Terraform's provider block
export GOOGLE_APPLICATION_CREDENTIALS="$KEY_FILE"
export GOOGLE_CLOUD_QUOTA_PROJECT="$PROJECT_ID"

printf "    ✅ Service Account activated and quota project set. Press Enter to run 'terraform apply'..."
read -r -p ""

terraform apply -auto-approve -parallelism=5

printf '\n'
printf "✅ Terraform apply complete.\n"
printf '\n'

INSTANCE=$(gcloud compute instances list --filter="name ~ ^win-jh" --format="value(name)")
printf "▶️ Press Enter to proceed with the next step: Redeploy jump host (crd token expired) \033[1;32m'${INSTANCE}'\033[0m"
read -r -p ""

# Make the update script executable
chmod +x "${WORKING_DIR}/main-crd-update.sh"

# Export the PROJECT_ID so the update script can use it, then call the script
export PROJECT=${PROJECT_ID}
"${WORKING_DIR}/main-crd-update.sh"

# Clean up the CRD auth file to ensure fresh credentials are requested next time
if [[ -f "${WORKING_DIR}/assets-jump-host/crd-auth-command.txt" ]]; then
    printf "    🧹 Cleaning up CRD auth file to ensure fresh credentials on next run...\n"
    rm "${WORKING_DIR}/assets-jump-host/crd-auth-command.txt"
fi

printf '\n'
printf "▶️ Press Enter to proceed with the next step: \033[1;32m'Deploy GDC Project via Terraform'\033[0m"
read -r -p ""


# (
#     cd "${WORKING_DIR}/gdc-gcp-project/tf" || exit
#     #terraform init
#     printf "▶️ Press Enter to proceed with the authentication as your admin account: "
#     read -r -p ""
#     gcloud auth login --update-adc
#     terraform apply -auto-approve -parallelism=5
# )


cd "${WORKING_DIR}/gdc-gcp-project/tf" || exit
#terraform init
# printf "▶️ Press Enter to proceed with the authentication as your admin account: "
# read -r -p ""
printf "    🔑 Unsetting GOOGLE_APPLICATION_CREDENTIALS to switch to user account...\n"
unset GOOGLE_APPLICATION_CREDENTIALS
    # Google's tools, including Terraform, look for credentials in a specific order of priority:
    # 
    # 1. __Highest Priority: `GOOGLE_APPLICATION_CREDENTIALS` Environment Variable.__ If this variable is set, it points directly to a service account's JSON key file. The tools will *always* use this file for authentication and will ignore all other forms of credentials.
    # 2. __Next Priority: User's Application Default Credentials (ADC).__ If the environment variable is *not* set, the tools will then look for the credentials file created by `gcloud auth login --update-adc`. This file contains the credentials for your personal user account.
    # 3. __Lowest Priority: Attached Service Account.__ (This applies when running on a GCP VM, not in your local shell).

#gcloud auth login --update-adc
#or test doing so non interactively:
printf "    🔑 Switching back to user account...\n"
gcloud config set account $GCLOUD_ACCOUNT
printf "    🔑 Updating ADC with user account persona ADCs...\n"
gcloud auth application-default login

printf "    🔄 Running Terraform for GDC Project. Press Enter to proceed\n"
read -r -p ""
terraform apply -auto-approve -parallelism=5


printf "    ✅ GDC Project deployment complete.\n"







printf '\n'
printf '\n'
printf "👊 Infrastructure deployed. Links to environment: \n"
printf "    ✅ gcp project: \033[1;31m'${PROJECT_ID}'\033[0m\n"
printf "    ✅ gcp project: \033[1;34m'https://console.cloud.google.com/compute/instances?project=${PROJECT_NAME}'\033[0m\n"
printf "    ✅ Jump host \033[1;31m'${INSTANCE}'\033[0m Chrome Remote Desktop Access: \033[1;34m'https://remotedesktop.google.com/access/'\033[0m (with \033[1;32m'${GCLOUD_ACCOUNT}'\033[0m chrome profile) \n"







SERVER_IP=$(gcloud compute instances list \
    --filter="name:vdc-pnetlab-*" \
    --limit=1 \
    --format="value(networkInterfaces[0].networkIP)")

SERVER_NAME=$(gcloud compute instances list \
    --filter="name:vdc-pnetlab-*" \
    --limit=1 \
    --format="value(name)")



## Process tied up to vDC web server port forwarding:
#
if [[ "$(uname -s)" == "Darwin" ]]; then
  #lsof -i :8080
  PORT_FORWARD="gcloud compute ssh root@${SERVER_NAME} --tunnel-through-iap -- -Nf -L 8080:${SERVER_IP}:443"
  #gcloud compute ssh root@vdc-pnetlab-v5-2 --tunnel-through-iap -- -Nf -L 8080:10.10.10.216:443
  PORT_FORWARD_CONNECT="gcloud compute ssh root@${SERVER_NAME} --tunnel-through-iap -- -L 8080:${SERVER_IP}:443"

  TUNNEL_PID=$(lsof -i :8080 | grep 'gnubby-ss' | awk 'NR==1 {print $2}')
  
else
  #netstat -tulpn | grep :8080
  #or on cloud shell:
  #ss -tlnp | grep 8080 
  PORT_FORWARD="gcloud compute ssh root@${SERVER_NAME} --tunnel-through-iap -- -Nf -L 127.0.0.1:8080:${SERVER_IP}:443"
  PORT_FORWARD_CONNECT="gcloud compute ssh root@${SERVER_NAME} --tunnel-through-iap -- -L 127.0.0.1:8080:${SERVER_IP}:443"
  
  TUNNEL_PID=$(netstat -tulpn | grep ':8080' | grep 'gnubby-ss' | awk '{print $7}' | cut -d/ -f1)
  
fi
#

## Example lsof output when connected:
#
# $ lsof -i :8080
# COMMAND     PID     USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
# gnubby-ss 24081 meillier    7u  IPv6 0xd06fb891555b776b      0t0  TCP localhost:http-alt (LISTEN)
# gnubby-ss 24081 meillier    8u  IPv4 0x6d1ee44bd1277d1f      0t0  TCP localhost:http-alt (LISTEN)



# 
# # 2. Immediately 
# TUNNEL_PID=$!



## Troubleshooting web preview on cloud shell
# curl -v http://localhost:8080
# echo "https://8080-$WEB_HOST"

/store/public/admin/main/view


printf "    💡 To setup port forwarding to vDC fabric manager: \033[1;31m'${PORT_FORWARD}'\033[0m \n"
#gcloud compute ssh root@vdc-pnetlab-v5-2 --tunnel-through-iap -- -Nf -L 8080:10.10.10.216:443
printf "    ✅ Access vDC fabric manager via: \033[1;34m'https://localhost:8080'\033[0m \n"
printf "    ✅ Terminate tunnel background process with: \033[1;31m'kill ${TUNNEL_PID}'\033[0m \n"

if [[ "$(uname -s)" == "Darwin" ]]; then
  printf "    💡 To check port used for port forwarding  : \033[1;31m'lsof -i :8080'\033[0m \n"
else
  printf "    💡 To check port used for port forwarding  : \033[1;31m'netstat -tulpn | grep :8080'\033[0m \n"
  printf "    or for cloudShell:\n"
  printf "    💡 To check port used for port forwarding  : \033[1;31m'ss -tlnp | grep 8080'\033[0m \n"
fi
printf '\n'


printf '\n'
printf " 👉 Next Steps: \n"
printf "    1 - Power on network fabric and win-DC windows controller on vDC fabric manager @ \033[1;34m'https://localhost:8080'\033[0m (run '\033[1;34m\$PORT_FORWARD)\033[0m'\n"
printf "    2 - Deploy Server via \033[1;31m'./servers/tf/main-servers.tf'\033[0m (servers list at \033[1;31m'terraform-servers.auto.tfvars'\033[0m)  \n"
printf "    3 - For GDC Bare metal, deploy the GCP fleet hub project via \033[1;31m'./gdc-gcp-project/tf/main-gdc.tf'\033[0m \n"
printf '\n'










## Chromebook:


# # __Built-in Linux Terminal (Best for Chromebooks)__ Most modern Chromebooks (2019+) support Linux apps through Crostini:
# # 
# # 1. __Enable Linux:__ Settings > Advanced > Developers > Linux development environment > Turn on
# # 
# # 2. __Install gcloud:__ In the Linux terminal:
# # 
# #    ```bash
# #    curl https://sdk.cloud.google.com | bash
# #    exec -l $SHELL
# #    gcloud init
# #    ```
# # 
# # 3. __Use the same tunnel command:__
# # 
# #    ```bash
# #    gcloud compute ssh root@vdc-pnetlab-v5-2 --tunnel-through-iap -- -Nf -L 8080:10.10.10.216:443
# #    ```
# # 
# # 4. __Access:__ Open Chrome browser and go to `https://localhost:8080`









#Authentication switched to Service Account:


## Useful Commands:
# gcloud compute ssh $SERVER_NAME --project=$PROJECT --zone=us-central1-a --tunnel-through-iap
# gcloud compute instances tail-serial-port-output $SERVER_NAME
# gcloud compute instances tail-serial-port-output $SERVER_NAME | grep -E '^|startup-script' --color=always
# SERVER_IP=$(gcloud compute instances list --filter="name:vdc-pnetlab-*" --limit=1 --format="value(networkInterfaces[0].networkIP)")
# SERVER_NAME=$(gcloud compute instances list --filter="name:vdc-pnetlab-*" --limit=1 --format="value(name)")
# gcloud compute ssh root@${SERVER_NAME} --tunnel-through-iap -- -Nf -L 8080:${SERVER_IP}:443
# lsof -i :8080

## Markdown Icons:
# 🚨
# ⚠️
# 💡
# ✅




#gcloud compute ssh root@vdc-pnetlab-v5-2 --tunnel-through-iap -- -Nf -L 8080:10.10.10.216:443
