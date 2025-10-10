#!/bin/bash

# Simple script to validate that service account key creation is allowed
# This tests the actual policy enforcement by attempting to create a service account key

set -e

# Read input from Terraform
eval "$(jq -r '@sh "PROJECT_ID=\(.project_id)"')"

# Create a simple test service account name
TEST_SA_NAME="policy-test-$(date +%s)"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >&2
}

# Function to cleanup
cleanup() {
    # Clean up any test resources
    gcloud iam service-accounts delete "${TEST_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
        --project="$PROJECT_ID" \
        --quiet 2>/dev/null || true
    rm -f /tmp/test-key-$$.json 2>/dev/null || true
}

# Set trap to cleanup on exit
trap cleanup EXIT

log "Testing service account key creation for project: $PROJECT_ID"

# Create a test service account
if ! gcloud iam service-accounts create "$TEST_SA_NAME" \
    --project="$PROJECT_ID" \
    --display-name="Policy Test SA" \
    --quiet 2>/dev/null; then
    
    log "ERROR: Failed to create test service account"
    jq -n --arg status "failed" --arg message "Failed to create test service account" \
        '{status: $status, message: $message}'
    exit 1
fi

log "Test service account created successfully"

# Retry loop to wait for policy propagation
MAX_RETRIES=10
RETRY_DELAY=30 # seconds

for (( i=1; i<=MAX_RETRIES; i++ )); do
    log "Attempt $i/$MAX_RETRIES: Trying to create service account key..."
    
    if gcloud iam service-accounts keys create /tmp/test-key-$$.json \
        --iam-account="${TEST_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
        --project="$PROJECT_ID" \
        --quiet 2>/dev/null; then
        
        log "Service account key creation succeeded - policy is active!"
        
        # Return success to Terraform
        jq -n --arg status "active" --arg message "Policy is active and service account key creation is allowed" \
            '{status: $status, message: $message}'
        exit 0
    fi
    
    log "Attempt $i failed. Waiting ${RETRY_DELAY}s for policy to propagate..."
    sleep $RETRY_DELAY
done

# If the loop completes without success, fail the script
log "ERROR: Service account key creation failed after $MAX_RETRIES attempts - policy constraint still active"
jq -n --arg status "failed" --arg message "Service account key creation failed after multiple retries - the iam.disableServiceAccountKeyCreation policy constraint is still active" \
    '{status: $status, message: $message}'
exit 1
