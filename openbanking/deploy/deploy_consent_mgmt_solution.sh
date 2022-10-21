#!/bin/bash

# Deploy all necessary artefacts to demonstrate how to use CloudEntity ACP and GCP Apigee to manage consent in Embedded Finance (Open Banking APIs)

if [ "$#" -ne 1 ]; then
    echo "This script deploys all necessary artefacts to demonstrate how to use CloudEntity ACP and GCP Apigee to manage consent in Embedded Finance (Open Banking APIs)"
    echo "Usage: deploy_consent_management_solution.sh CONFIG_FILE"
    exit
fi

# Check prerequisites
TEST_GC=$(which gcloud)
if [[ -z "$TEST_GC" ]];
then
    echo "This script requires gcloud, the Google Cloud CLI tool. Installation instructions: https://cloud.google.com/sdk/docs/install"
    exit -1
fi

# Check prerequisites
TEST_JQ=$(which jq)
if [[ -z "$TEST_JQ" ]];
then
    echo "This script requires jq. If using Linux, install it by running: sudo apt-get install jq"
    exit -1
fi

TEST_AP_CLI=$(which apigeecli)
if [[ -z "$TEST_AP_CLI" ]];
then
    echo "This script requires apigeecli. Download the appropriate binary for your platform from https://github.com/apigee/apigeecli/releases"
    exit -1
fi

CONFIG_FILE=$1
# Get absolute path to config file
export CONFIG_FILE_ABS_PATH=$(echo "$(cd "$(dirname "$CONFIG_FILE")" && pwd)/$(basename "$CONFIG_FILE")")

# Set up environment variables
echo "========================================================================="
echo "--> Setting up environment using file "
echo "    $CONFIG_FILE_ABS_PATH"
echo "========================================================================="
source $CONFIG_FILE_ABS_PATH

# # Enable APIs and grant required permission in the GCP Project
# gcloud config set project $PROJECT_ID
# echo "========================================================================="
# echo "--> Enabling required GCP APIs..."
# echo "----> Enabling Cloud Build APIs ..."
# echo "========================================================================="
# gcloud services enable cloudbuild.googleapis.com
# echo "========================================================================="
# echo "----> Enabling Cloud Run APIs ..."
# echo "========================================================================="
# gcloud services enable run.googleapis.com
# echo "========================================================================="
# echo "----> Enabling Secret Manager APIs ..."
# echo "========================================================================="
# gcloud services enable secretmanager.googleapis.com

# # Grant required permissions to Cloud Build service account
# PROJECT_NUMBER=$(gcloud projects describe  $PROJECT_ID --format 'value(projectNumber)')
# CB_SVC_ACCOUNT="$PROJECT_NUMBER@cloudbuild.gserviceaccount.com"
# echo "=================================================================================================="
# echo "--> Granting required permissions to Cloud Build service account:"
# echo "      $CB_SVC_ACCOUNT"
# echo "=================================================================================================="
# gcloud projects add-iam-policy-binding $PROJECT_ID \
#         --member="serviceAccount:$CB_SVC_ACCOUNT" \
#         --role="roles/cloudbuild.builds.builder"

# gcloud projects add-iam-policy-binding $PROJECT_ID \
#         --member="serviceAccount:$CB_SVC_ACCOUNT" \
#         --role="roles/iam.serviceAccountUser"

# gcloud projects add-iam-policy-binding $PROJECT_ID \
#         --member="serviceAccount:$CB_SVC_ACCOUNT" \
#         --role="roles/run.developer"

# gcloud projects add-iam-policy-binding $PROJECT_ID \
#         --member="serviceAccount:$CB_SVC_ACCOUNT" \
#         --role="roles/secretmanager.admin"

# # Grant required permissions to Cloud Run service account
# CR_SVC_ACCOUNT="$PROJECT_NUMBER-compute@developer.gserviceaccount.com"
# echo "=================================================================================================="
# echo "--> Granting required permissions to Cloud Run service account: "
# echo "      $CR_SVC_ACCOUNT"
# echo "=================================================================================================="
# gcloud projects add-iam-policy-binding $PROJECT_ID \
#         --member="serviceAccount:$CR_SVC_ACCOUNT" \
#         --role="roles/secretmanager.secretAccessor"

# # Deploy Apigee Artefacts
# echo "========================================================================="
# echo "--> Deploying Apigee artefacts..."
# echo "========================================================================="
# deploy/apigee-artefacts-deploy.sh

# Clone CloudEntity quickstart repo
echo "==================================================================================================="
echo "--> Cloning Cloud Entity openbanking-quickstart repo from"
echo "        https://github.com/cloudentity/openbanking-quickstart"
echo "==================================================================================================="
# mkdir deploy/tmp
# pushd deploy
# git clone https://github.com/cloudentity/openbanking-quickstart tmp/openbanking-quickstart
# popd

pushd deploy/tmp/openbanking-quickstart


# # Create Cloud secrets required for files that are mounted as volumes by the consent page app and the demo client app (Financroo)
# echo "========================================================================="
# echo "--> Creating Google Cloud secrets to store certificates used by apps"
# echo "========================================================================="
# ../../create_update_secret.sh ce-tpp-cert ./data/tpp_cert.pem
# ../../create_update_secret.sh ce-tpp-key ./data/tpp_key.pem
# ../../create_update_secret.sh ce-cert-auth ./data/ca.pem

# # Re-read the environment file to get the latest values updated from the previous Apigee deployment step
# source $CONFIG_FILE_ABS_PATH


# # Deploy consent app page
# echo "========================================================================="
# echo "--> Deploying consent page app as a CloudRun function...."
# echo "========================================================================="
# gcloud builds submit --region=$REGION --config ../../cloudbuild-consent-app.yaml --substitutions=_CE_ACP_ISSUER_URL="$CE_ACP_ISSUER_URL",_CE_ACP_CONSENT_SCREEN_CLIENT_ID="$CE_ACP_CONSENT_SCREEN_CLIENT_ID",_CE_ACP_CONSENT_SCREEN_CLIENT_SECRET="$CE_ACP_CONSENT_SCREEN_CLIENT_SECRET",_APIGEE_X_ENDPOINT="$APIGEE_X_ENDPOINT",_APIGEE_CE_CLIENT_ID="$APIGEE_CE_CLIENT_ID",_APIGEE_CE_CLIENT_SECRET="$APIGEE_CE_CLIENT_SECRET" .

# # Get URL for consent page app
# CONSENT_APP_URL=$(gcloud run services describe ce-consent-page --platform managed --region=$REGION --format 'value(status.url)')
# echo "========================================================================="
# echo "--> Updating consent page app configuration...."
# echo "========================================================================="
# gcloud beta run services add-iam-policy-binding --region=$REGION --member=allUsers --role=roles/run.invoker ce-consent-page
# echo "==================================================================================================="
# echo "The consent page app has been deployed at $CONSENT_APP_URL "
# echo "==================================================================================================="


# Deploy consent self service app 
echo "========================================================================="
echo "--> Deploying consent self service app as a CloudRun function...."
echo "========================================================================="
export CE_ACP_HOSTNAME=$(echo $CE_ACP_AUTH_SERVER  |  awk -F/ '{print $3}')
export CE_ACP_TENANT=$(echo $CE_ACP_AUTH_SERVER  |  awk -F/ '{print $4}')
export CE_ACP_WORKSPACE=$(echo $CE_ACP_AUTH_SERVER  |  awk -F/ '{print $5}')
export CE_ACP_MTLS_ISSUER=$(curl $CE_ACP_AUTH_SERVER/.well-known/openid-configuration -s | jq -r '.mtls_issuer')
export CE_ACP_MTLS_HOSTNAME=$(echo $CE_ACP_MTLS_ISSUER  |  awk -F/ '{print $3}')
# gcloud builds submit --region=$REGION --config ../../cloudbuild-consent-self-svc-app.yaml --substitutions=_CE_ACP_ISSUER_URL="$CE_ACP_ISSUER_URL",_APIGEE_X_ENDPOINT="$APIGEE_X_ENDPOINT",_APIGEE_CE_CLIENT_ID="$APIGEE_CE_CLIENT_ID",_APIGEE_CE_CLIENT_SECRET="$APIGEE_CE_CLIENT_SECRET",_CE_ACP_HOSTNAME="$CE_ACP_HOSTNAME",_CE_ACP_BANK_AUTH_SERVER_ID="$CE_ACP_BANK_AUTH_SERVER_ID",_CE_ACP_TENANT="$CE_ACP_TENANT",_CE_ACP_SELF_SVC_CLIENT_ID="$CE_ACP_SELF_SVC_CLIENT_ID",_CE_ACP_SYSTEM_CLIENT_ID="$CE_ACP_SYSTEM_CLIENT_ID",_CE_ACP_SYSTEM_CLIENT_SECRET="$CE_ACP_SYSTEM_CLIENT_SECRET",_CE_ACP_SELF_SVC_BACKEND_CLIENT_ID="$CE_ACP_SELF_SVC_BACKEND_CLIENT_ID",_CE_ACP_SELF_SVC_BACKEND_CLIENT_SECRET="$CE_ACP_SELF_SVC_BACKEND_CLIENT_SECRET",_CE_ACP_MTLS_HOSTNAME="$CE_ACP_MTLS_HOSTNAME",_CE_ACP_WORKSPACE="$CE_ACP_WORKSPACE" .
gcloud builds submit --region=$REGION --config ../../cloudbuild-consent-self-svc-app.yaml --substitutions=_CE_ACP_ISSUER_URL="$CE_ACP_ISSUER_URL",_APIGEE_X_ENDPOINT="$APIGEE_X_ENDPOINT",_APIGEE_CE_CLIENT_ID="$APIGEE_CE_CLIENT_ID",_APIGEE_CE_CLIENT_SECRET="$APIGEE_CE_CLIENT_SECRET",_CE_ACP_HOSTNAME="$CE_ACP_HOSTNAME",_CE_ACP_BANK_AUTH_SERVER_ID="$CE_ACP_BANK_AUTH_SERVER_ID",_CE_ACP_TENANT="$CE_ACP_TENANT",_CE_ACP_SELF_SVC_CLIENT_ID="$CE_ACP_SELF_SVC_CLIENT_ID",_CE_ACP_SYSTEM_CLIENT_ID="$CE_ACP_SYSTEM_CLIENT_ID",_CE_ACP_SYSTEM_CLIENT_SECRET="$CE_ACP_SYSTEM_CLIENT_SECRET",_CE_ACP_SELF_SVC_BACKEND_CLIENT_ID="$CE_ACP_SELF_SVC_BACKEND_CLIENT_ID",_CE_ACP_SELF_SVC_BACKEND_CLIENT_SECRET="$CE_ACP_SELF_SVC_BACKEND_CLIENT_SECRET",_CE_ACP_MTLS_HOSTNAME="$CE_ACP_MTLS_HOSTNAME",_CE_ACP_WORKSPACE="$CE_ACP_WORKSPACE" --no-source

# Get URL for consent self service app
CONSENT_SELF_SVC_URL=$(gcloud run services describe ce-consent-self-svc --platform managed --region=$REGION --format 'value(status.url)')
echo "========================================================================="
echo "--> Updating consent self service app configuration...."
echo "========================================================================="
gcloud beta run services add-iam-policy-binding --region=$REGION --member=allUsers --role=roles/run.invoker ce-consent-self-svc
echo "==================================================================================================="
echo "The consent self service app has been deployed at $CONSENT_SELF_SVC_URL "
echo "==================================================================================================="


# # Deploy demo client app (Financroo)
# echo "========================================================================="
# echo "--> Deploying demo client app -Financroo- as a CloudRun function...."
# echo "========================================================================="
# gcloud builds submit --region=$REGION --config ../../cloudbuild-financroo-app.yaml --substitutions=_CE_ACP_HOSTNAME="$CE_ACP_HOSTNAME",_CE_ACP_MTLS_HOSTNAME="$CE_ACP_MTLS_HOSTNAME",_CE_ACP_TENANT="$CE_ACP_TENANT",_CE_ACP_WORKSPACE="$CE_ACP_WORKSPACE",_APIGEE_X_ENDPOINT="$APIGEE_X_ENDPOINT",_CE_ACP_TPP_CLIENT_ID="$CE_ACP_TPP_CLIENT_ID" .

# # Let all users access the deployed cloud function
# gcloud beta run services add-iam-policy-binding --region=$REGION --member=allUsers --role=roles/run.invoker ce-demo-client

# # Get URL for consent page app
# DEMO_CLIENT_APP_URL=$(gcloud run services describe ce-demo-client --platform managed --region=$REGION --format 'value(status.url)')
# # Update config of deployed client app
# echo "========================================================================="
# echo "--> Updating demo client configuration...."
# echo "========================================================================="
# gcloud run services update ce-demo-client --region=$REGION --update-env-vars=UI_URL=$DEMO_CLIENT_APP_URL
# gcloud beta run services add-iam-policy-binding --region=$REGION --member=allUsers --role=roles/run.invoker ce-demo-client

# echo "==================================================================================================="
# echo " The demo client app has now been deployed."
# echo " You can test this solution by accessing the "
# echo " demo client app at:                           "
# echo "   $DEMO_CLIENT_APP_URL                        "
# echo "================================================="
popd

# Remove temporary artefacts
# rm -rf deploy/tmp/

# echo "DEMO_CLIENT_APP_URL=$DEMO_CLIENT_APP_URL" >> deploy/ce_workspace.env
# echo "CONSENT_APP_URL=$CONSENT_APP_URL" >> deploy/ce_workspace.env
echo "CONSENT_SELF_SVC_URL=$CONSENT_SELF_SVC_URL"  >> deploy/ce_workspace.env

echo Done