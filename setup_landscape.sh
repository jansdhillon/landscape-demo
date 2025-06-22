#!/bin/bash
NOW=$(date -u +"%Y-%m-%dT%H:%M:%S")

LANDSCAPE_ROOT_URL="$1"
ADMIN_EMAIL="$2"
ADMIN_PASSWORD="$3"
GPG_PRIVATE_KEY_CONTENT="$4"
SERIES="$5"

timeout=300 # 5 minutes
start_time=$(date +%s)
while true; do
  current_time=$(date +%s)
  elapsed=$((current_time - start_time))

  if (( elapsed >= timeout )); then
      printf "Timeout reached after %d seconds.\n" $timeout >&2
      break
  fi

  login_response=$(curl -skX POST "https://${LANDSCAPE_ROOT_URL}/api/v2/login" \
    -d "{\"email\": \"${ADMIN_EMAIL}\", \"password\": \"${ADMIN_PASSWORD}\"}")

  JWT=$(printf "%s" $login_response | yq -r '.token')

  if [ "${JWT:-}" != "null" ] && [ -n "${JWT:-}" ]; then
    printf 'Login successful.\n' >&2
    break
  else
    printf "Login failed.\n." >&2
    printf "Response: %s\n" "${login_response:-}" >&2
    printf "Trying again...\n." >&2
    sleep 5
  fi
done

rest_api_request() {
  local method=$1
  local url=$2
  local body=${3:-}

  response=""
  if [ -n "${body:-}" ]; then
    response=$(curl -skX "${method}" "${url}" \
      -H "Authorization: Bearer ${JWT}" \
      -H "Content-Type: application/json" \
      -d "$body")
  else
    response=$(curl -skX "${method}" "${url}" \
      -H "Authorization: Bearer ${JWT}")
  fi

  printf "Response:\n" >&2
  printf '%s\n' "$response" | yq >&2
}

# enable auto registration

SET_PREFERENCES_URL="https://${LANDSCAPE_ROOT_URL}/api/v2/preferences"

rest_api_request "PATCH" "${SET_PREFERENCES_URL}" '{"auto_register_new_computers": true}'

# Create a script

WELCOME_SCRIPT_CODE=$(base64 -w 0 <<EOF
#!/bin/bash
echo "Welcome to Landscape!" | tee landscape.txt
EOF
)

CREATE_SCRIPT_URL="https://${LANDSCAPE_ROOT_URL}/api?action=CreateScript&version=2011-08-01&code=${WELCOME_SCRIPT_CODE}&title=Welcome+Script&script_type=V2&access_group=global"

rest_api_request "GET" "${CREATE_SCRIPT_URL}"

# Create a script profile

CREATE_SCRIPT_PROFILE_URL="https://${LANDSCAPE_ROOT_URL}/api/v2/script-profiles"

BODY=$(
  cat <<EOF
{
  "all_computers": true,
  "script_id": 1,
  "tags": [],
  "time_limit": 300,
  "title": "Welcome to Landscape",
  "trigger": {
    "trigger_type": "event",
    "event_type": "post_enrollment",
    "start_after": "${NOW}"
  },
  "username": "root"
}
EOF
)

rest_api_request "POST" "${CREATE_SCRIPT_PROFILE_URL}" "${BODY}"

# Import GPG key into Landscape

PRIVATE_KEY_NAME="gpg-key"

IMPORT_GPG_KEY_URL="https://${LANDSCAPE_ROOT_URL}/api/?action=ImportGPGKey&version=2011-08-01&name=${PRIVATE_KEY_NAME}&material=${GPG_PRIVATE_KEY_CONTENT}"

rest_api_request "POST" "${IMPORT_GPG_KEY_URL}"

# Create distribution

CREATE_DISTRIBUTION_URL="https://${LANDSCAPE_ROOT_URL}/api/?action=CreateDistribution&version=2011-08-01&name=ubuntu&access_group=global"

rest_api_request "POST" "${CREATE_DISTRIBUTION_URL}"

# Add series/pockets

POCKETS=("release" "updates" "security" "proposed" "backports")
POCKETS_STR=""
for i in "${!POCKETS[@]}"; do
    POCKETS_STR="${POCKETS_STR}&pockets.$((i+1))=${POCKETS[i]}"
done
POCKETS_STR="${POCKETS_STR#&}"

COMPONENTS=("main" "universe" "multiverse" "restricted")
COMPONENTS_STR=""
for i in "${!COMPONENTS[@]}"; do
    COMPONENTS_STR="${COMPONENTS_STR}&components.$((i+1))=${COMPONENTS[i]}"
done
COMPONENTS_STR="${COMPONENTS_STR#&}"

CREATE_SERIES_URL="https://${LANDSCAPE_ROOT_URL}/api/?action=CreateSeries&version=2011-08-01&name=${SERIES}&distribution=ubuntu&${POCKETS_STR}&${COMPONENTS_STR}&architectures.1=amd64&gpg_key=${PRIVATE_KEY_NAME}&mirror_uri=http://archive.ubuntu.com/ubuntu"

rest_api_request "POST" "${CREATE_SERIES_URL}"

# Only one pocket can be synced at a time

SYNC_BACKPORTS_POCKET_URL="https://${LANDSCAPE_ROOT_URL}/api/?action=SyncMirrorPocket&version=2011-08-01&name=backports&series=${SERIES}&distribution=ubuntu"

rest_api_request "POST" "${SYNC_BACKPORTS_POCKET_URL}"

# Create repo profile for it

CREATE_REPOSITORY_PROFILE_URL="https://${LANDSCAPE_ROOT_URL}/api/v2/repositoryprofiles"

BODY=$(
  cat <<EOF
{
    "all_computers": false,
    "apt_sources": [],
    "pockets": [1, 2, 3, 4, 5],
    "title": "apply-ubuntu-${SERIES}-mirror",
    "tags": ["${SERIES}"]
}
EOF
)

rest_api_request "POST" "${CREATE_REPOSITORY_PROFILE_URL}" "${BODY}"

echo '{"status": "done"}'
