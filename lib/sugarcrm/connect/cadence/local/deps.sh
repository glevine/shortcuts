#!/usr/bin/env zsh

set -o errexit
set -o nounset
set -o pipefail

chores::sugarcrm::connect::cadence::local::deps::resolve() {
    if [[ ! -d "${CADENCE}" ]]; then
        git clone --recurse-submodules --remote-submodules -o upstream "${CADENCE_REMOTE_UPSTREAM}" "${CADENCE}"
    fi

    git -C "${CADENCE}" submodule update --init --recursive --remote --rebase

    if ! git -C "${CADENCE}" remote | grep -q "^origin$"; then
        git -C "${CADENCE}" remote add origin "${CADENCE_REMOTE_ORIGIN}"
    fi

    # PostgreSQL is needed to compile psycopg. The database is actually run in
    # docker.
    if ! command -v postgres &>/dev/null; then
        brew install postgresql
    else
        brew upgrade postgresql
    fi

    # An empty secret satisfies the requirements.
    # The secret will be loaded from SUGAR_OAUTH_SA_CLIENT_SECRETS in custom_local.py.
    touch "${CADENCE}/backend/main/src/resources/local/sugar_connect_sa_secret"

    # Add settings to custom_local.py.
    touch "${CADENCE}/backend/main/src/config/settings/custom_local.py"
    chores::file::append "PUBLIC_TENANT_BASE_URL = 'clbspot.localhost.com:28081'" "${CADENCE}/backend/main/src/config/settings/custom_local.py"
    chores::file::append "PUBLIC_TENANT_BASE_URL_FULL = 'https://' + PUBLIC_TENANT_BASE_URL" "${CADENCE}/backend/main/src/config/settings/custom_local.py"
    chores::file::append "SESSION_COOKIE_DOMAIN = '.clbspot.localhost.com'" "${CADENCE}/backend/main/src/config/settings/custom_local.py"
    chores::file::append "HTTP_SCHEME = 'https'" "${CADENCE}/backend/main/src/config/settings/custom_local.py"
    chores::file::append "SUGAR_OAUTH_STS_SERVER = 'https://sts-stage.service.sugarcrm.com'" "${CADENCE}/backend/main/src/config/settings/custom_local.py"

    # Some settings must be added manually.
    echo ""
    echo "Add SUGAR_OAUTH_CLIENT_ID, SUGAR_OAUTH_SA_CLIENTS, and SUGAR_OAUTH_SA_CLIENT_SECRETS to ${CADENCE}/backend/main/src/config/settings/custom_local.py"
    echo ""
}
