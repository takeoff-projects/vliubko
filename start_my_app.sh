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
    _log "INFO" "Creating bucket $TF_STATE_BUCKET_NAME.."
    gsutil mb -b -p $GOOGLE_CLOUD_PROJECT gs://$TF_STATE_BUCKET_NAME 2&>/dev/null || true
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

if [ $create_init_resources == "true" ]; then
  _create_terraform_bucket
  _create_gsa "terraform" $GOOGLE_CLOUD_PROJECT
  _create_gsa "github" $GOOGLE_CLOUD_PROJECT
fi

# will be used by terraform code
export TF_VAR_google_project_id=$GOOGLE_CLOUD_PROJECT
export GOOGLE_APPLICATION_CREDENTIALS=$GSA_KEY_FILEPATH

cd ops/terraform
if [ $create_init_resources == "true" ]; then
  set +e
  _init_terraform
  while [ $? -ne 0 ]; do
    _log "INFO" "need some time until Google Cloud IAM will propagate (required for terraform bucket access)..."
    sleep 30
    _init_terraform
  done
  set -e
fi

# _apply_terraform

# back from terraform dir
cd "../.."

if [ $create_init_resources == "true" ]; then
  echo "Please open Firebase and activate Auth section manually in the browser..."
  open "https://console.firebase.google.com/project/$GOOGLE_CLOUD_PROJECT/authentication"
fi


CLOUDSQL_INSTANCE_NAME=$(gcloud sql instances list --project $GOOGLE_CLOUD_PROJECT --format json | jq -r '.[].name')
CLOUDSQL_INSTANCE_IP_ADDRESS=$(gcloud sql instances list --project $GOOGLE_CLOUD_PROJECT --format json | jq -r '.[].ipAddresses[].ipAddress')
CLOUDSQL_DB_NAME="oms-lite"
CLOUDSQL_DB_USER="oms-lite"
CLOUDSQL_DB_PASSWORD="oms-lite"

expect init_scripts/cloudsql_autoconnect.exp $CLOUDSQL_INSTANCE_NAME $CLOUDSQL_DB_USER $CLOUDSQL_DB_PASSWORD $GOOGLE_CLOUD_PROJECT
