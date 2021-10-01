#!/usr/bin/env bash

# e causes the script to stop on errors
# u causes it to error on undefined variables being used
# o pipefail causes a non-zero exit code from any command in a pipeline to fail the script too (rather than just the last command.)
set -Eeuo pipefail
trap _cleanup SIGINT SIGTERM ERR EXIT

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

usage() {
  cat << EOF # remove the space between << and EOF, this is due to web plugin issue
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-f] -p param_value arg1 [arg2...]

Script description here.

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info
-f, --flag      Some flag description
-p, --param     Some param description
EOF
  exit
}

_cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
}

_setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
  else
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
  fi
}

_msg() {
  echo >&2 -e "${1-}"
}

# Invoking the function is _log "INFO" "Some status" or _log "WARN" "Something concerning" etc.
_log() {
  local -r level="$1"
  local -r message="$2"
  local -r timestamp=$(date +"%Y-%m-%d %H:%M:%S")

  >&2 echo -e "${timestamp} [${level}] ${message}"
}

_assert_is_installed() {
  local -r name="$1"

  if [[ ! $(command -v "$name") ]]; then
    _log "ERROR" "The binary '$name' is required by this script but is not installed or in the system's PATH."
    exit 1
  fi
}

_die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  _log "FATAL" "$msg"
  exit "$code"
}

_parse_params() {
  # default values of variables set from params
  create_init_resources=true
  GOOGLE_CLOUD_PROJECT=''

  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    -v | --verbose) set -x ;;
    --no-color) NO_COLOR=1 ;;
    -c | --create_init_resources) create_init_resources=false ;; # example flag
    -g | --google_cloud_project) # example named parameter
      GOOGLE_CLOUD_PROJECT="${2-}"
      shift
      ;;
    -?*) _die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  args=("$@")

  # check required params and arguments
  [[ -z "${GOOGLE_CLOUD_PROJECT-}" ]] && _die "Missing required parameter: google_cloud_project"
#   [[ ${#args[@]} -eq 0 ]] && _die "Missing script arguments"

  return 0
}

_create_terraform_bucket() {
    _log "INFO" "Creating terraform state bucket $TF_STATE_BUCKET_NAME.."

    if gsutil ls -p $GOOGLE_CLOUD_PROJECT | grep "gs://$TF_STATE_BUCKET_NAME"; then
      _log "INFO" "Bucket already exists"
	  else
		  gsutil mb -p $GOOGLE_CLOUD_PROJECT -b on gs://$TF_STATE_BUCKET_NAME
	  fi
}

_create_gsa_key() {
	local gsa_name=$1
	local google_project=$2
  local gsa_key_file=$3

  _log "INFO" "Creating GSA key for $gsa_name..."
  
  gcloud iam service-accounts keys create "$(pwd)/$gsa_name-gsa-key.json" \
    --iam-account="$gsa_name@$google_project.iam.gserviceaccount.com"
}

_create_gsa() {
	local gsa_name=$1
	local google_project=$2

  _log "INFO" "Creating GSA for $gsa_name..."
  # check if exist already
  gsa_exist=$(gcloud iam service-accounts list --project $google_project --format json | jq '.[] | select (.displayName == "'"$gsa_name"'")')
  if [ -z "$gsa_exist" ]; then
    _log "INFO" "Creating GSA (google service account) for $gsa_name..."
  else
    _log "INFO" "GSA $gsa_name already exist, skipping.."
    if test -f "$GSA_KEY_FILEPATH"; then
      echo "$GSA_KEY_FILEPATH exists and will be used"
      return
    fi
    _create_gsa_key $gsa_name $google_project $GSA_KEY_FILEPATH
    return
  fi

  gcloud iam service-accounts create $gsa_name \
    --description="SA for $gsa_name stuff" \
    --display-name="$gsa_name" \
    --project "$google_project"

  _log "INFO" "Grant owner role for $gsa_name GSA..."
  gcloud projects add-iam-policy-binding $google_project \
  --member="serviceAccount:$gsa_name@$google_project.iam.gserviceaccount.com" \
  --role="roles/owner" --format json
  
  gcloud projects add-iam-policy-binding $google_project \
  --member="serviceAccount:$gsa_name@$google_project.iam.gserviceaccount.com" \
  --role="roles/storage.objectAdmin" --format json

  gcloud projects add-iam-policy-binding $google_project \
  --member="serviceAccount:$gsa_name@$google_project.iam.gserviceaccount.com" \
  --role="roles/storage.admin" --format json

  _create_gsa_key $gsa_name $google_project $GSA_KEY_FILEPATH
}

_init_terraform() {
    terraform init -backend-config="bucket=$TF_STATE_BUCKET_NAME"
}

_apply_terraform() {
  _log "INFO" "Running terraform apply in $(pwd)"
  terraform apply
}

#---------------------------
# SCRIPT STARTS HERE
#---------------------------

# preparations
_parse_params "$@"
_setup_colors

# make sure tools are installed
_assert_is_installed "jq"
_assert_is_installed "gcloud"
_assert_is_installed "git"
_assert_is_installed "terraform"

# check the args/flags
_log "INFO" "${GREEN}Read parameters:${NOFORMAT}"
_log "INFO" "- create_init_resources: ${create_init_resources}"
_log "INFO" "- google_cloud_project: ${GOOGLE_CLOUD_PROJECT}"
_log "INFO" "- arguments: ${args[*]-}"


TF_STATE_BUCKET_NAME="terraform-state-bucket-$GOOGLE_CLOUD_PROJECT"
GSA_KEY_FILEPATH="$(pwd)/terraform-gsa-key.json"
APP_NAME="oms-lite"

# grant owner role for the current takeoff user
gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT --member=user:$(gcloud auth list --format="value(account)" | grep "@takeoff.com") --role=roles/owner &>/dev/null

# enable this API to be able to terraform other APIs..
gcloud services enable serviceusage.googleapis.com --project $GOOGLE_CLOUD_PROJECT

if [ $create_init_resources == "true" ]; then
  _create_terraform_bucket
  _create_gsa "terraform" $GOOGLE_CLOUD_PROJECT
  _create_gsa "github" $GOOGLE_CLOUD_PROJECT
fi

# will be used by terraform code
export TF_VAR_google_project_id=$GOOGLE_CLOUD_PROJECT
export TF_VAR_cloud_run_url="$(gcloud run services --quiet describe $APP_NAME --region us-central1 --project $GOOGLE_CLOUD_PROJECT --format json 2&>/dev/null | jq -r '.status.url')"

if [ "$TF_VAR_cloud_run_url" = "" ]; then
  export TF_VAR_cloud_run_url="https://google.com"
fi
export GOOGLE_APPLICATION_CREDENTIALS=$GSA_KEY_FILEPATH

cd ops/terraform
if [ $create_init_resources == "true" ]; then
  set +e
  rm -rf .terraform .terraform.lock.hcl
  _init_terraform
  while [ $? -ne 0 ]; do
    _log "INFO" "need some time until Google Cloud IAM will propagate (required for terraform bucket access)..."
    sleep 30
    _init_terraform
  done
  set -e
fi

_apply_terraform

_log "INFO" "Collecting terraform outputs.."
CLOUDSQL_INSTANCE_CONNECTION_NAME=$(terraform output --raw cloudsql_instance_connection_name)

# TODO: get values from secret manager
CLOUDSQL_DB_NAME=$(terraform output --raw cloudsql_db_name)
CLOUDSQL_DB_USER=$(terraform output --raw cloudsql_db_user)
CLOUDSQL_DB_PASSWORD=$(terraform output --raw cloudsql_db_password)
APP_GSA_EMAIL=$(terraform output --raw app_service_account_email)


# back from terraform dir
cd "../.."

if [ $create_init_resources == "true" ]; then
  echo "Please open Firebase and activate Auth section manually in the browser..."
  open "https://console.firebase.google.com/project/$GOOGLE_CLOUD_PROJECT/authentication"

  read -p "
Did you enable Firebase Auth in the $GOOGLE_CLOUD_PROJECT project?

  >> Continue? (y/N) " decision
  if [ "$decision" != "Y" ] && [ "$decision" != "y" ]; then
      _log "ERROR" "Aborted."
      exit 1
  fi
  _log "INFO" "Deploy fixtures to the Firestore..."
  python3 init_scripts/init_data_firestore.py
fi

API_URL=https://identitytoolkit.googleapis.com/admin/v2
TOKEN=$(gcloud auth application-default print-access-token)
FIREBASE_API_KEY=$(curl -s "${API_URL}/projects/$GOOGLE_CLOUD_PROJECT/config" \
    --header "Authorization: Bearer $TOKEN" \
    --header 'Accept: application/json' \
    --compressed | jq -r .client.apiKey)

_log "INFO" "Starting CloudSQL proxy..."
docker rm -f cloudsql_proxy
docker run --name cloudsql_proxy -d \
      -v $GSA_KEY_FILEPATH:/config \
      -p 5432:5432 \
      gcr.io/cloudsql-docker/gce-proxy:1.19.1 /cloud_sql_proxy \
      -instances=${CLOUDSQL_INSTANCE_CONNECTION_NAME}=tcp:0.0.0.0:5432 \
      -credential_file=/config

# wait 5 sec until proxy will be available
sleep 5

_log "INFO" "Perform DB migrations in the CloudSQL..."
make migrate-up

# hack to kill this container (it could listen on 5432)
docker rm -f cloudsql_proxy 2&>/dev/null

_log "INFO" "Docker build and push $APP_NAME"
TAGGED_IMAGE=gcr.io/$GOOGLE_CLOUD_PROJECT/$APP_NAME:$(date +%y-%m-%d).local.$USER
docker build -t $TAGGED_IMAGE .
docker push $TAGGED_IMAGE

_log "INFO" "Deploy $APP_NAME to Cloud Run"
gcloud beta run deploy $APP_NAME \
  --project $GOOGLE_CLOUD_PROJECT \
  --service-account $APP_GSA_EMAIL \
  --image $TAGGED_IMAGE \
  --region us-central1 \
  --platform managed \
  --allow-unauthenticated \
  --add-cloudsql-instances=$CLOUDSQL_INSTANCE_CONNECTION_NAME \
  --update-env-vars=ENV=PROD \
  --update-secrets=INSTANCE_CONNECTION_NAME=cloudsql_oms_lite_instance_connection:latest \
  --update-secrets=POSTGRES_DB=cloudsql_oms_lite_db_name:latest \
  --update-secrets=POSTGRES_USER=cloudsql_oms_lite_db_user:latest \
  --update-secrets=POSTGRES_PASSWORD=cloudsql_oms_lite_db_password:latest \

export TF_VAR_cloud_run_url="$(gcloud run services describe $APP_NAME --region us-central1 --project $GOOGLE_CLOUD_PROJECT --format json | jq -r '.status.url')"
cd ops/terraform
terraform apply -target='google_api_gateway_api_config.api_gw' -target='google_api_gateway_gateway.api_gw'
OMS_LITE_API_API_GATEWAY=$(terraform output --raw api_gateway_url)
# back from terraform dir
cd "../.."

echo "GCP_PROJECT_ID = $GOOGLE_CLOUD_PROJECT"
echo "GCP_SA_KEY is:"
python -m base64 -e < github-gsa-key.json
  read -p "
Please copy updated secrets for a new project the application repo (to enable CI/CD).
https://github.com/takeoff-projects/vliubko/settings/secrets/actions

  >> Continue? (y/N) " decision
  if [ "$decision" != "Y" ] && [ "$decision" != "y" ]; then
      _log "ERROR" "Aborted."
      exit 1
  fi

gsed -i "s/const FIREBASE_API_KEY = .*/const FIREBASE_API_KEY = \"$FIREBASE_API_KEY\"/" public/firebase.js
gsed -i "s/const OMS_LITE_API_API_GATEWAY = .*/const OMS_LITE_API_API_GATEWAY = \"$OMS_LITE_API_API_GATEWAY\"/" public/firebase.js
gsed -i "s/const GOOGLE_PROJECT_ID = .*/const GOOGLE_PROJECT_ID = \"$GOOGLE_CLOUD_PROJECT\"/" public/firebase.js

git add public/firebase.js
git commit -m "GOOGLE_PROJECT_ID changed to $GOOGLE_PROJECT_ID"
git push

_log "INFO" "Success. Check the https://github.com/takeoff-projects/vliubko and/or  $TF_VAR_cloud_run_url"
