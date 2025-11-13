#!/bin/bash



echo ""
echo "=========================================="
echo "#### Individual User Addition Section ####"
echo "=========================================="


USERS_GWID="C00vjdu8i"
MEMBER="user:admin@powerm-1.altostrat.com"

# Function to check if a single user already has permissions
check_single_user_permission() {
    local bucket_name="$1"
    local role="$2"
    local user="$3"
    
    echo "Checking if ${user} already has ${role} permissions on ${bucket_name}..."
    
    # Get current IAM policy for the bucket
    local current_policy=$(gcloud storage buckets get-iam-policy "${bucket_name}" --format="json" 2>/dev/null)
    
    if [ -z "$current_policy" ]; then
        echo "❌ Unable to retrieve bucket IAM policy. Bucket may not exist or insufficient permissions."
        return 1
    fi
    
    if echo "$current_policy" | jq -r '.bindings[] | select(.role=="'$role'") | .members[]' 2>/dev/null | grep -q "^${user}$"; then
        echo "✅ User permissions already exist - ${user} already processed"
        return 0
    else
        echo "❌ ${user} does not have ${role} - processing needed"
        return 1
    fi
}

# Check if individual user already has permissions
if check_single_user_permission "gs://vdc-tf-bucket" "roles/storage.objectViewer" "${MEMBER}"; then
    echo "🚀 Skipping individual user setup - ${MEMBER} already has required permissions."
    echo "Script completed successfully."
    exit 0
fi

echo "🔧 Processing individual user: ${MEMBER}"
echo "    - is:${USERS_GWID}" >> drs-policy.yaml
gcloud resource-manager org-policies set-policy drs-policy.yaml --project=vdc-tf

# Function to check if the policy has propagated
check_policy_propagation() {
    local gwid="$1"
    local project="$2"
    local max_attempts=20
    local attempt=1
    
    echo "Checking if policy has propagated for GWID: ${gwid}"
    
    while [ $attempt -le $max_attempts ]; do
        echo "Attempt ${attempt}/${max_attempts}: Checking policy propagation..."
        
        # Get the current org policy and check if our GWID is in the allowedValues
        if gcloud resource-manager org-policies describe constraints/iam.allowedPolicyMemberDomains --project="${project}" --format="value(listPolicy.allowedValues)" | grep -q "is:${gwid}"; then
            echo "✅ Policy has propagated successfully. GWID ${gwid} is now allowed."
            return 0
        fi
        
        echo "⏳ Policy not yet propagated. Waiting 15 seconds before retry..."
        sleep 15
        ((attempt++))
    done
    
    echo "❌ Policy propagation timeout after $((max_attempts * 15)) seconds."
    return 1
}

# Wait for policy propagation
if check_policy_propagation "${USERS_GWID}" "vdc-tf"; then
    echo "Proceeding with IAM role assignment..."
    
    ROLE="roles/storage.objectViewer"
    gcloud storage buckets add-iam-policy-binding "gs://vdc-tf-bucket" --member="${MEMBER}" --role="${ROLE}" --project vdc-tf --quiet
    
    if [[ $? -eq 0 ]]; then
        echo "✅ Successfully granted ${ROLE} to ${MEMBER}"
        log_processed_user "${USERS_GWID}" "${MEMBER}"
    else
        echo "❌ Failed to grant ${ROLE} to ${MEMBER}"
    fi
else
    echo "❌ Cannot proceed with IAM role assignment. Policy propagation failed."
    exit 1
fi

# Show final processing summary
show_processing_summary

