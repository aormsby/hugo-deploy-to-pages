#!/bin/sh
# shellcheck disable=SC2034
# shellcheck disable=SC1091

# get action directory for sourcing subscripts
ACTION_PARENT_DIR=$(dirname "$(dirname "$0")")

# source script to handle message output
. "${ACTION_PARENT_DIR}"/util/output.sh

if [ -z "${GITHUB_ACTIONS}" ] || [ "${GITHUB_ACTIONS}" = false ]; then
    write_out "b" "\nRunning in LOCAL MODE..."

    # set test mode, default false
    INPUT_TEST_MODE=true
    INPUT_SOURCE_BRANCH="main"
    INPUT_RELEASE_BRANCH="test3"

    # INPUT_SUBMODULE_RELEASE_BRANCH="test3"
    # INPUT_HUGO_PUBLISH_DIRECTORY="public"
    # INPUT_COMMIT_MESSAGE="insert commit message here"

    INPUT_GIT_CONFIG_USER="Geronimo Jones"
    INPUT_GIT_CONFIG_EMAIL="GJones@geronimo.woah"
    INPUT_GIT_CONFIG_PULL_REBASE=true
fi

if [ -n "${INPUT_SUBMODULE_RELEASE_BRANCH}" ]; then
    PUBLISH_TO_SUBMODULE=true
else
    PUBLISH_TO_SUBMODULE=false
fi

# Fork to live action or test mode based on INPUT_TEST_MODE flag
if [ "${INPUT_TEST_MODE}" = true ]; then
    write_out "b" "Running TESTS...\n"
    . "${ACTION_PARENT_DIR}"/entry/run_tests.sh
    write_out "b" "Tests Complete"
else
    write_out "b" "Running ACTION...\n"
    . "${ACTION_PARENT_DIR}"/entry/run_action.sh
    write_out "b" "Action Complete"
fi
