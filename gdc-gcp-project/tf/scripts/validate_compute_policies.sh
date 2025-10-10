#!/bin/bash

set -e

# Read project_id from the JSON input from Terraform
eval "$(jq -r '@sh "PROJECT_ID=\(.project_id)"')"

# Policies to check for. These are the constraints we are setting in main.tf.
# We just need to wait for them to appear in the list.
POLICIES_TO_CHECK=(
    "compute.requireShieldedVm"
    "compute.vmCanIpForward"
    "compute.vmExternalIpAccess"
    "compute.disableSerialPortAccess"
    "compute.requireOsLogin"
    "compute.disableNestedVirtualization"
    "compute.trustedImageProjects"
)

TIMEOUT_SECONDS=300 # 5 minutes
SLEEP_INTERVAL=10

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >&2
}

check_policies_presence() {
    log "Checking for presence of org policies..."
    
    # Get the list of policies set on the project
    local set_policies
    set_policies=$(gcloud org-policies list --project="$PROJECT_ID" --format="value(constraint)")
    
    local all_found=true
    for policy in "${POLICIES_TO_CHECK[@]}"; do
        if ! echo "$set_policies" | grep -q -w "$policy"; then
            log "⏳ Policy '$policy' not found yet."
            all_found=false
        else
            log "✅ Policy '$policy' found."
        fi
    done

    if [[ "$all_found" == "true" ]]; then
        return 0 # Success
    else
        return 1 # Still waiting
    fi
}

start_time=$(date +%s)
while true; do
    if check_policies_presence; then
        log "🎉 All required org policies are present."
        jq -n --arg status "success" '{"status": $status}'
        exit 0
    fi

    current_time=$(date +%s)
    elapsed_time=$((current_time - start_time))

    if [ $elapsed_time -ge $TIMEOUT_SECONDS ]; then
        log "❌ Timeout reached. Not all policies appeared in the list in time."
        jq -n --arg status "failed" --arg message "Timeout waiting for policies to appear" \
            '{"status": $status, "message": $message}'
        exit 1
    fi

    log "Retrying in $SLEEP_INTERVAL seconds..."
    sleep $SLEEP_INTERVAL
done
