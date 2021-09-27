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
  create_tf_init_resources=true
  GOOGLE_CLOUD_PROJECT=''

  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    -v | --verbose) set -x ;;
    --no-color) NO_COLOR=1 ;;
    -c | --create_tf_init_resources) create_tf_init_resources=false ;; # example flag
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
    gsutil mb -p $GOOGLE_CLOUD_PROJECT gs://$TF_STATE_BUCKET_NAME 2&>/dev/null || true
}

_create_terraform_gsa_key() {
  _log "INFO" "Creating GSA key for terraform..."
  
  gcloud iam service-accounts keys create $GSA_KEY_FILEPATH \
    --iam-account="terraform@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com"
}

_create_terraform_gsa() {
    # check if exist already
    terraform_gsa=$(gcloud iam service-accounts list --project $GOOGLE_CLOUD_PROJECT --format json | jq '.[] | select (.displayName == "terraform")')
    if [ -z "$terraform_gsa" ]; then
      _log "INFO" "Creating GSA (google service account) for terraform..."
    else
      _log "INFO" "GSA already exist, skipping.."
      if test -f "$GSA_KEY_FILEPATH"; then
        echo "$GSA_KEY_FILEPATH exists and will be used"
        return
      fi
      _create_terraform_gsa_key
      return
    fi

    gcloud iam service-accounts create terraform \
    --description="SA for terraform stuff" \
    --display-name="terraform" \
    --project ${GOOGLE_CLOUD_PROJECT}

    _log "INFO" "Grant owner role for terraform GSA..."
    gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} \
    --member="serviceAccount:terraform@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com" \
    --role="roles/owner" \
    2&>/dev/null

    # wait some time until IAM will propagate (required for terraform bucket access)
    sleep 15
    _create_terraform_gsa_key
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
_log "INFO" "- create_tf_init_resources: ${create_tf_init_resources}"
_log "INFO" "- google_cloud_project: ${GOOGLE_CLOUD_PROJECT}"
_log "INFO" "- arguments: ${args[*]-}"


TF_STATE_BUCKET_NAME="terraform-state-bucket-$GOOGLE_CLOUD_PROJECT"
GSA_KEY_FILEPATH="$(pwd)/terraform-gsa-key.json"

if [ $create_tf_init_resources == "true" ]; then
  _create_terraform_gsa
  _create_terraform_bucket
fi

# will be used by terraform code
export TF_VAR_google_project_id=$GOOGLE_CLOUD_PROJECT
export GOOGLE_APPLICATION_CREDENTIALS=$GSA_KEY_FILEPATH

cd terraform
if [ $create_tf_init_resources == "true" ]; then
  _init_terraform
fi
_apply_terraform

if [ $create_tf_init_resources == "true" ]; then
  echo "Please open Firebase and activate Auth section manually in the browser..."
  open "https://console.firebase.google.com/project/$GOOGLE_CLOUD_PROJECT/authentication"
fi
