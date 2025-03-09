#!/bin/bash

# Load environment variables
source .env

# Function to handle errors
handle_error() {
    echo "Error: $1"
    exit 1
}

# Create the project if it doesn't exist
if ! gcloud projects describe $GCP_PROJECT_ID > /dev/null 2>&1; then
    echo "Creating GCP project..."
    gcloud projects create $GCP_PROJECT_ID || handle_error "Failed to create project"
else
    echo "Project $GCP_PROJECT_ID already exists"
fi

# Set the project
gcloud config set project $GCP_PROJECT_ID || handle_error "Failed to set project"

# Verify and enable billing
echo "Checking billing status..."
BILLING_STATUS=$(gcloud billing projects describe $GCP_PROJECT_ID --format="value(billingEnabled)" 2>/dev/null)

if [[ "$BILLING_STATUS" != "True" ]]; then
    echo "Enabling billing..."
    gcloud billing projects link $GCP_PROJECT_ID \
        --billing-account=$GCP_BILLING_ACCOUNT || handle_error "Failed to enable billing"
    
    # Wait for billing to propagate
    echo "Waiting for billing to be enabled..."
    sleep 30
else
    echo "Billing already enabled"
fi

# Double-check billing status
BILLING_STATUS=$(gcloud billing projects describe $GCP_PROJECT_ID --format="value(billingEnabled)" 2>/dev/null)
if [[ "$BILLING_STATUS" != "True" ]]; then
    handle_error "Billing is still not enabled after attempt. Please check your billing account."
fi

# Set up budget
echo "Setting up budget..."
gcloud billing budgets create \
    --billing-account=$GCP_BILLING_ACCOUNT \
    --display-name="Project Budget" \
    --budget-amount=25 \
    --threshold-rule=percent=0.5 \
    --threshold-rule=percent=0.75 \
    --threshold-rule=percent=0.9 \
    --filter-projects=$GCP_PROJECT_ID || handle_error "Failed to create budget"

# Enable IAM service first as it's required for other services
if ! gcloud services list --enabled --project=$GCP_PROJECT_ID | grep -q "iam.googleapis.com"; then
    echo "Enabling IAM service..."
    gcloud services enable iam.googleapis.com --project=$GCP_PROJECT_ID || handle_error "Failed to enable IAM service"
else
    echo "IAM service already enabled"
fi

# Set the quota project now that IAM is enabled
echo "Setting quota project..."
gcloud auth application-default set-quota-project $GCP_PROJECT_ID || echo "Warning: Failed to set quota project, continuing..."

# Enable remaining required services
echo "Enabling required services..."
SERVICES=(
    "firebase.googleapis.com"
    "run.googleapis.com"
    "firestore.googleapis.com"
    "identitytoolkit.googleapis.com"
    "artifactregistry.googleapis.com"
    "containerregistry.googleapis.com"
)

for SERVICE in "${SERVICES[@]}"; do
    if ! gcloud services list --enabled --project=$GCP_PROJECT_ID | grep -q $SERVICE; then
        echo "Enabling $SERVICE..."
        gcloud services enable $SERVICE --project=$GCP_PROJECT_ID || handle_error "Failed to enable $SERVICE"
    else
        echo "$SERVICE already enabled"
    fi
done

# Create service account if it doesn't exist
SERVICE_ACCOUNT_EMAIL="setup-service-account@$GCP_PROJECT_ID.iam.gserviceaccount.com"
if ! gcloud iam service-accounts describe $SERVICE_ACCOUNT_EMAIL --project=$GCP_PROJECT_ID > /dev/null 2>&1; then
    echo "Creating service account..."
    gcloud iam service-accounts create setup-service-account \
        --display-name="Initial Setup Service Account" --project=$GCP_PROJECT_ID || handle_error "Failed to create service account"
else
    echo "Service account already exists"
fi

# Grant roles to service account if not already granted
echo "Checking service account roles..."
if ! gcloud projects get-iam-policy $GCP_PROJECT_ID \
    --flatten="bindings[].members" \
    --format='table(bindings.role)' \
    --filter="bindings.members:$SERVICE_ACCOUNT_EMAIL" | grep -q "roles/owner"; then
    echo "Granting owner role to service account..."
    gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
        --member="serviceAccount:$SERVICE_ACCOUNT_EMAIL" \
        --role="roles/owner" || handle_error "Failed to grant owner role"
else
    echo "Service account already has owner role"
fi

# Create and download service account key if it doesn't exist
if [ ! -f "serviceAccountKey.json" ]; then
    echo "Creating service account key..."
    gcloud iam service-accounts keys create serviceAccountKey.json \
        --iam-account=$SERVICE_ACCOUNT_EMAIL || handle_error "Failed to create service account key"
else
    echo "Service account key already exists"
fi

# Initialize Firestore database
if ! gcloud firestore databases list --project=$GCP_PROJECT_ID | grep -q "(default)"; then
    echo "Creating Firestore database..."
    gcloud firestore databases create --location=$REGION --project=$GCP_PROJECT_ID || handle_error "Failed to create Firestore database"
else
    echo "Firestore database already exists"
fi

# Initialize Firebase project
echo "Initializing Firebase project..."
if ! firebase projects:list | grep -q $GCP_PROJECT_ID; then
    echo "Adding Firebase to GCP project..."
    firebase projects:addfirebase $GCP_PROJECT_ID || handle_error "Failed to add Firebase to project"
    
    echo "Configuring Firebase iOS app..."
    # Create iOS app without requiring immediate configuration
    firebase apps:create ios --bundle-id=com.wedgegolf.app --project=$GCP_PROJECT_ID || echo "Warning: Failed to create Firebase iOS app. You can configure this later in the Firebase console."
else
    echo "Firebase already initialized"
fi

echo "Initial setup complete. Service account key saved to serviceAccountKey.json"