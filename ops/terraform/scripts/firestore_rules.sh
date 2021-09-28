#!/usr/bin/env bash

# Unfortunately, there is no Terraform resource for Firestore rules:
# https://github.com/hashicorp/terraform-provider-google/issues/8263

set -e

NUMBER_OF_RETRIES=0
SUCCESS=false
until [ "$SUCCESS" = "true" ] || [ "$NUMBER_OF_RETRIES" -eq 5 ]
do
    RESPONSE=$(curl --silent \
                    --compressed \
                    --request GET \
                    --header "X-Goog-User-Project: $PROJECT" \
                    --header "Authorization: Bearer $TOKEN" \
                    --header 'Accept: application/json' \
                    "${API_URL}/projects/${PROJECT}/releases")
    ERROR=$(echo $RESPONSE | jq -r '.error')

    if [ "$ERROR" = "null" ]; then
        SUCCESS=true
        OLD_RULESET_NAME=$(echo $RESPONSE | jq -r '.releases[]? | select(.name | test("cloud.firestore$")) | .rulesetName')
    else
        NUMBER_OF_RETRIES=$((NUMBER_OF_RETRIES+1))
        sleep 30
    fi
done

if [ "$SUCCESS" = "false" ]; then
    echo "Could not get ruleset"
    exit 1
fi

if [ -n "$OLD_RULESET_NAME" ] && [ "$OLD_RULESET_NAME" != "null" ]; then
    OLD_RULES=$(curl --silent \
                     --compressed \
                     --request GET \
                     --header "X-Goog-User-Project: $PROJECT" \
                     --header "Authorization: Bearer $TOKEN" \
                     --header 'Accept: application/json' \
                     "${API_URL}/${OLD_RULESET_NAME}" \
                    | jq -r '.source.files[0].content')

    if [ "$OLD_RULES" = "$RULES" ]; then
        echo "No change"
        exit 0
    fi
fi

RULES_JSON=$(jq -c -r -n --arg content "$RULES" '{source: {files: [{name: "firestore.rules", content: $content}]}}')
NEW_RULESET_NAME=$(curl --silent \
                        --compressed \
                        --request POST \
                        --header "X-Goog-User-Project: $PROJECT" \
                        --header "Authorization: Bearer $TOKEN" \
                        --header 'Accept: application/json' \
                        --header 'Content-Type: application/json' \
                        --data "$RULES_JSON" \
                        "${API_URL}/projects/${PROJECT}/rulesets" | jq -r '.name')

RELEASE_NAME="projects/${PROJECT}/releases/cloud.firestore"
RELEASE_JSON=$(jq -c -r -n \
                  --arg name "$RELEASE_NAME" \
                  --arg rulesetName "$NEW_RULESET_NAME" \
                  '{release: {name: $name, rulesetName: $rulesetName}}')
curl --silent \
     --compressed \
     --request PATCH \
     --header "X-Goog-User-Project: $PROJECT" \
     --header "Authorization: Bearer $TOKEN" \
     --header 'Accept: application/json' \
     --header 'Content-Type: application/json' \
     --data "$RELEASE_JSON" \
     "${API_URL}/${RELEASE_NAME}"
