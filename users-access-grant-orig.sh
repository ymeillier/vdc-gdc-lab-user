#! /bin/bash


# Either assign as a group of user or individually




# opiont1: didn't work cause argolis block workspace groups from alowing non domain member to join.




# Option 2: 
# For a Group of Users
# 
# # Where user gest his Google Workspace ID (GWID)
#     - Sign in to the Google Admin console at admin.google.com.
#     - Navigate to the Menu: Account > Account settings > Profile.
#     - Look for the Customer ID field. This is your organization's unique GWCID.

# 1. Define the Google Workspace IDs

USERS_GWIDS_STRING="C00oe4dka,C04hayrrf,C03i4b1mc,C03m3q4nk,C024o5jnw,C01pabg93,C04cafwbh,C00jeftrb,C0411ffp5,C01ncgc0r,C00jeftrb,C036k920f,C03w1wcxd,C03vdm1qn,C01ln7av3,C00vjdu8i"
USER_EMAILS=(
    "user:admin@haneyr.altostrat.com"
    "user:admin@andrewksmith.altostrat.com"
    "user:admin@stevenmchen.altostrat.com"
    "user:admin@chrissavage.altostrat.com"
    "user:admin@wmunji.altostrat.com"
    "user:admin@bdau.altostrat.com"
    "user:admin@katur.altostrat.com"
    "user:admin@plaliberte.altostrat.com"
    "user:admin@gabrielsleiman.altostrat.com"
    "user:admin@brucethelen.altostrat.com"
    "user:admin@powerm-1.altostrat.com"

)

# Function to check if users already have IAM permissions on the bucket
check_existing_permissions() {
    local bucket_name="$1"
    local role="$2"
    local users_array=("${@:3}")
    
    echo "Checking if users already have ${role} permissions on ${bucket_name}..."
    
    # Get current IAM policy for the bucket
    local current_policy=$(gcloud storage buckets get-iam-policy "${bucket_name}" --format="json" 2>/dev/null)
    
    if [ -z "$current_policy" ]; then
        echo "❌ Unable to retrieve bucket IAM policy. Bucket may not exist or insufficient permissions."
        return 1
    fi
    
    local users_with_permission=0
    local total_users=${#users_array[@]}
    
    for user in "${users_array[@]}"; do
        if echo "$current_policy" | jq -r '.bindings[] | select(.role=="'$role'") | .members[]' 2>/dev/null | grep -q "^${user}$"; then
            echo "✅ ${user} already has ${role}"
            ((users_with_permission++))
        else
            echo "❌ ${user} does not have ${role}"
        fi
    done
    
    echo "Permission check: ${users_with_permission}/${total_users} users have required permissions"
    
    if [ $users_with_permission -eq $total_users ]; then
        echo "✅ All users already have required permissions. Skipping group setup."
        return 0
    else
        echo "⚠️ Not all users have required permissions. Group setup needed."
        return 1
    fi
}

# Initialize tracking files (stored in current working directory)
PROCESSED_USERS_LOG="processed_users.log"
PROCESSED_GWIDS_LOG="processed_gwids.log"

echo "📁 Log files will be stored in: $(pwd)"
echo "  - User logs: $(pwd)/${PROCESSED_USERS_LOG}"
echo "  - GWID logs: $(pwd)/${PROCESSED_GWIDS_LOG}"
echo ""

# Function to log processed user
log_processed_user() {
    local gwid="$1"
    local user_email="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Log user email with timestamp
    echo "${timestamp} - ${user_email}" >> "${PROCESSED_USERS_LOG}"
    
    # Log GWID with timestamp
    echo "${timestamp} - ${gwid}" >> "${PROCESSED_GWIDS_LOG}"
    
    echo "📝 Logged processed user: ${user_email} (GWID: ${gwid})"
}

# Function to show processing summary
show_processing_summary() {
    echo ""
    echo "=========================================="
    echo "#### Processing Summary ####"
    echo "=========================================="
    
    if [[ -f "${PROCESSED_USERS_LOG}" ]]; then
        local total_processed=$(wc -l < "${PROCESSED_USERS_LOG}")
        echo "📊 Total users processed so far: ${total_processed}"
        echo ""
        echo "Recent processed users:"
        tail -5 "${PROCESSED_USERS_LOG}" | while read line; do
            echo "  ✅ ${line}"
        done
        echo ""
        echo "📁 Full logs available in:"
        echo "  - ${PROCESSED_USERS_LOG} (user emails)"
        echo "  - ${PROCESSED_GWIDS_LOG} (GWIDs)"
    else
        echo "📊 No users processed yet."
    fi
    echo ""
}

# Check if group setup is needed
BUCKET_NAME="gs://vdc-tf-bucket"
ROLE="roles/storage.objectViewer"

if check_existing_permissions "${BUCKET_NAME}" "${ROLE}" "${USER_EMAILS[@]}"; then
    echo "🚀 Skipping group setup - all users already have required permissions."
    echo "💡 Note: Log files are only created when new users are actually processed."
    if [[ -f "${PROCESSED_USERS_LOG}" ]]; then
        echo "📋 Existing log files found with previous processing history."
    else
        echo "📋 No log files exist yet (will be created when users are processed)."
    fi
    echo "Proceeding to individual user section..."
    echo ""
else
    echo "🔧 Running group setup..."



IFS=',' read -r -a USERS_GWIDS_ARRAY <<< "$USERS_GWIDS_STRING"
cat << EOF > drs-policy.yaml
constraint: constraints/iam.allowedPolicyMemberDomains
listPolicy:
 inheritFromParent: true
 allowedValues:
$(for gwid in "${USERS_GWIDS_ARRAY[@]}"; do echo "    - is:$gwid"; done)
EOF

# 
#       #A final correct policy yaml would look like:
#       #  constraint: constraints/iam.allowedPolicyMemberDomains
#       #  listPolicy:
#       #    inheritFromParent: true
#       #    allowedValues: 
#       #      - is:C01XXXcu
#       #      - is:C01w3mXXX
# 
# # 2. then apply the policy:
gcloud resource-manager org-policies set-policy drs-policy.yaml --project=vdc-tf

# Function to check if all GWIDs in the policy have propagated
check_all_gwids_propagation() {
    local gwids_array=("$@")
    local project="vdc-tf"
    local max_attempts=20
    local attempt=1
    
    echo "Checking if policy has propagated for all ${#gwids_array[@]} GWIDs..."
    
    while [ $attempt -le $max_attempts ]; do
        echo "Attempt ${attempt}/${max_attempts}: Checking policy propagation..."
        
        # Get the current org policy values
        local current_policy=$(gcloud resource-manager org-policies describe constraints/iam.allowedPolicyMemberDomains --project="${project}" --format="value(listPolicy.allowedValues)" 2>/dev/null)
        
        if [ -z "$current_policy" ]; then
            echo "⏳ Policy not yet available. Waiting 15 seconds before retry..."
            sleep 15
            ((attempt++))
            continue
        fi
        
        local all_propagated=true
        local propagated_count=0
        
        # Check each GWID
        for gwid in "${gwids_array[@]}"; do
            if echo "$current_policy" | grep -q "is:${gwid}"; then
                ((propagated_count++))
            else
                all_propagated=false
                echo "⏳ GWID ${gwid} not yet propagated..."
            fi
        done
        
        echo "Progress: ${propagated_count}/${#gwids_array[@]} GWIDs propagated"
        
        if [ "$all_propagated" = true ]; then
            echo "✅ All GWIDs have propagated successfully!"
            return 0
        fi
        
        echo "⏳ Not all GWIDs propagated yet. Waiting 15 seconds before retry..."
        sleep 15
        ((attempt++))
    done
    
    echo "❌ Policy propagation timeout after $((max_attempts * 15)) seconds."
    echo "❌ Only ${propagated_count}/${#gwids_array[@]} GWIDs have propagated."
    return 1
}

# Wait for all GWIDs to propagate before proceeding with IAM assignments
if check_all_gwids_propagation "${USERS_GWIDS_ARRAY[@]}"; then
    echo "Proceeding with IAM role assignments for all users..."
    
    # 3. Then give users access to the bucket:
    ROLE="roles/storage.objectViewer"
    #USER_EMAILS_init=$USER_EMAILS

    BUCKET_NAME="gs://vdc-tf-bucket"
    successful_assignments=0
    failed_assignments=0
    
    for i in "${!USER_EMAILS[@]}"; do
        MEMBER="${USER_EMAILS[$i]}"
        GWID="${USERS_GWIDS_ARRAY[$i]}"
        echo "Adding: ${MEMBER}"
        gcloud storage buckets add-iam-policy-binding "${BUCKET_NAME}" \
            --member="${MEMBER}" \
            --role="${ROLE}" \
            --project="vdc-tf" \
            --quiet
        if [[ $? -eq 0 ]]; then
            echo "✅ Successfully added: ${MEMBER}"
            log_processed_user "${GWID}" "${MEMBER}"
            ((successful_assignments++))
        else
            echo "❌ Failed to add: ${MEMBER}"
            ((failed_assignments++))
        fi
    done
    
    echo ""
    echo "=== IAM Assignment Summary ==="
    echo "✅ Successful: ${successful_assignments}"
    echo "❌ Failed: ${failed_assignments}"
    echo "📊 Total: $((successful_assignments + failed_assignments))"
    
else
    echo "❌ Cannot proceed with IAM role assignments. Policy propagation failed for some GWIDs."
    exit 1
fi

fi  # End of group setup conditional













































# --> see user-access-grant-indiv.sh
# 
# echo ""
# echo "=========================================="
# echo "#### Individual User Addition Section ####"
# echo "=========================================="
# 
# 
# USERS_GWID="C00vjdu8i"
# MEMBER="user:admin@powerm-1.altostrat.com
# "
# 
# # Function to check if a single user already has permissions
# check_single_user_permission() {
#     local bucket_name="$1"
#     local role="$2"
#     local user="$3"
#     
#     echo "Checking if ${user} already has ${role} permissions on ${bucket_name}..."
#     
#     # Get current IAM policy for the bucket
#     local current_policy=$(gcloud storage buckets get-iam-policy "${bucket_name}" --format="json" 2>/dev/null)
#     
#     if [ -z "$current_policy" ]; then
#         echo "❌ Unable to retrieve bucket IAM policy. Bucket may not exist or insufficient permissions."
#         return 1
#     fi
#     
#     if echo "$current_policy" | jq -r '.bindings[] | select(.role=="'$role'") | .members[]' 2>/dev/null | grep -q "^${user}$"; then
#         echo "✅ User permissions already exist - ${user} already processed"
#         return 0
#     else
#         echo "❌ ${user} does not have ${role} - processing needed"
#         return 1
#     fi
# }
# 
# # Check if individual user already has permissions
# if check_single_user_permission "gs://vdc-tf-bucket" "roles/storage.objectViewer" "${MEMBER}"; then
#     echo "🚀 Skipping individual user setup - ${MEMBER} already has required permissions."
#     echo "Script completed successfully."
#     exit 0
# fi
# 
# echo "🔧 Processing individual user: ${MEMBER}"
# echo "    - is:${USERS_GWID}" >> drs-policy.yaml
# gcloud resource-manager org-policies set-policy drs-policy.yaml --project=vdc-tf
# 
# # Function to check if the policy has propagated
# check_policy_propagation() {
#     local gwid="$1"
#     local project="$2"
#     local max_attempts=20
#     local attempt=1
#     
#     echo "Checking if policy has propagated for GWID: ${gwid}"
#     
#     while [ $attempt -le $max_attempts ]; do
#         echo "Attempt ${attempt}/${max_attempts}: Checking policy propagation..."
#         
#         # Get the current org policy and check if our GWID is in the allowedValues
#         if gcloud resource-manager org-policies describe constraints/iam.allowedPolicyMemberDomains --project="${project}" --format="value(listPolicy.allowedValues)" | grep -q "is:${gwid}"; then
#             echo "✅ Policy has propagated successfully. GWID ${gwid} is now allowed."
#             return 0
#         fi
#         
#         echo "⏳ Policy not yet propagated. Waiting 15 seconds before retry..."
#         sleep 15
#         ((attempt++))
#     done
#     
#     echo "❌ Policy propagation timeout after $((max_attempts * 15)) seconds."
#     return 1
# }
# 
# # Wait for policy propagation
# if check_policy_propagation "${USERS_GWID}" "vdc-tf"; then
#     echo "Proceeding with IAM role assignment..."
#     
#     ROLE="roles/storage.objectViewer"
#     gcloud storage buckets add-iam-policy-binding "gs://vdc-tf-bucket" --member="${MEMBER}" --role="${ROLE}" --project vdc-tf --quiet
#     
#     if [[ $? -eq 0 ]]; then
#         echo "✅ Successfully granted ${ROLE} to ${MEMBER}"
#         log_processed_user "${USERS_GWID}" "${MEMBER}"
#     else
#         echo "❌ Failed to grant ${ROLE} to ${MEMBER}"
#     fi
# else
#     echo "❌ Cannot proceed with IAM role assignment. Policy propagation failed."
#     exit 1
# fi
# 
# # Show final processing summary
# show_processing_summary
