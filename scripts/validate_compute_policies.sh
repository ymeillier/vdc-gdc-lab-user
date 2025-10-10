#!/bin/bash

set -e

# Read project_id and gcp_zone from the JSON input from Terraform
eval "$(jq -r '@sh "PROJECT_ID=\(.project_id)" "GCP_ZONE=\(.gcp_zone)"')"

# Define the expected state for each policy based on actual JSON structure
declare -A POLICY_CHECKS
POLICY_CHECKS=(
    ["compute.requireShieldedVm"]="spec.rules[0].enforce=false"
    ["compute.vmCanIpForward"]="spec.rules[0].allowAll=true"
    ["compute.vmExternalIpAccess"]="spec.rules[0].allowAll=true"
    ["compute.disableSerialPortAccess"]="spec.rules[0].enforce=false"
    ["compute.requireOsLogin"]="spec.rules[0].enforce=false"
    ["compute.disableNestedVirtualization"]="spec.rules[0].enforce=false"
    ["compute.trustedImageProjects"]="spec.rules[0].values.allowedValues[0]=projects/windows-cloud"
)

TIMEOUT_SECONDS=180 # 3 minutes
SLEEP_INTERVAL=10

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >&2
}

check_effective_policies() {
    local waiting_on_policies=()
    
    for policy in "${!POLICY_CHECKS[@]}"; do
        local expected_state="${POLICY_CHECKS[$policy]}"
        local key_path="${expected_state%%=*}"
        local expected_value="${expected_state#*=}"
        
        local effective_policy_json
        if ! effective_policy_json=$(gcloud org-policies describe "$policy" --project="$PROJECT_ID" --effective --format="json" 2>/dev/null); then
            waiting_on_policies+=("$policy (not available)")
            continue
        fi

        local actual_value
        actual_value=$(echo "$effective_policy_json" | jq -r ".${key_path}" 2>/dev/null)

        if [[ "$actual_value" != "$expected_value" ]]; then
            waiting_on_policies+=("$policy (expected: $expected_value, got: $actual_value)")
        fi
    done

    if [ ${#waiting_on_policies[@]} -eq 0 ]; then
        return 0 # Success
    else
        # Log waiting status to stderr (not stdout, which must be JSON only)
        log "Waiting for policies to propagate: ${waiting_on_policies[*]}"
        return 1 # Still waiting
    fi
}

# --- Main Logic ---

# Check if the jump host already exists. If so, skip validation.
if gcloud compute instances describe "win-jh-${PROJECT_ID}" --zone="${GCP_ZONE}" --project="${PROJECT_ID}" &>/dev/null; then
    log "✅ Jump host already exists. Skipping policy validation."
    jq -n --arg status "success" '{"status": $status}'
    exit 0
fi

# Fast path: Check once. If it succeeds, exit immediately.
if check_effective_policies; then
    log "🎉 All required org policies are already in the correct state."
    jq -n --arg status "success" '{"status": $status}'
    exit 0
fi

log "One or more policies have not propagated. Entering retry loop..."
start_time=$(date +%s)
while true; do
    # Re-check policies
    if check_effective_policies; then
        log "🎉 All required org policies have propagated successfully."
        jq -n --arg status "success" '{"status": $status}'
        exit 0
    fi

    current_time=$(date +%s)
    elapsed_time=$((current_time - start_time))

    if [ $elapsed_time -ge $TIMEOUT_SECONDS ]; then
        log "❌ Timeout reached. Not all policies propagated in time."
        jq -n --arg status "failed" --arg message "Timeout waiting for policies to propagate" \
            '{"status": $status, "message": $message}'
        exit 1
    fi

    log "Retrying in $SLEEP_INTERVAL seconds..."
    sleep $SLEEP_INTERVAL
done
