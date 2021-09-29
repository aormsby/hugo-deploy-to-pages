#!/bin/sh

# get action directory for sourcing subscripts
ACTION_PARENT_DIR=$(dirname "$(dirname "$0")")

# shellcheck disable=SC1091
# source script to handle message output
. "${ACTION_PARENT_DIR}"/util/output.sh

if [ -z "${GITHUB_ACTIONS}" ] || [ "${GITHUB_ACTIONS}" = false ]; then
    write_out "b" "\nRunning in LOCAL MODE..."
    
    # set test mode, default false
    INPUT_TEST_MODE=true

    # shellcheck disable=SC2034
	INPUT_SOURCE_BRANCH="main"
    # shellcheck disable=SC2034
    INPUT_RELEASE_BRANCH="test3"

    # INPUT_SUBMODULE_BRANCH="test3"
    # INPUT_HUGO_PUBLISH_DIRECTORY="public"
	# INPUT_COMMIT_MESSAGE="insert commit message here"
	# SOURCE_HASH="jfkdlf"
    
    # shellcheck disable=SC2034
    INPUT_GIT_CONFIG_USER="Geronimo Jones"
    # shellcheck disable=SC2034
    INPUT_GIT_CONFIG_EMAIL="GJones@geronimo.woah"
    # shellcheck disable=SC2034
    INPUT_GIT_CONFIG_PULL_REBASE=true
fi

# TODO: set values on run based on input - do I even need these?
# vars used by script, do no edit
# FRESH="${INPUT_FRESH_BUILD}"
# IGNORE_FILES=". .. .git CNAME ${INPUT_DO_NOT_DELETE_FILES}" # space-delimited array of files to protect when input_fresh_build option is set to true
# DEPLOY_TO_SUBMODULE="false" # false by default, set to true if input_submodule_branch is set

# shellcheck disable=SC2034
CURRENT_SOURCE_HEAD=$(git rev-parse "${INPUT_SOURCE_BRANCH}")

# Fork to live action or test mode based on INPUT_TEST_MODE flag
if [ "${INPUT_TEST_MODE}" = true ]; then
    write_out "b" "Running TESTS...\n"
    # shellcheck disable=SC1091
    . "${ACTION_PARENT_DIR}"/entry/run_tests.sh
    write_out "b" "Tests Complete"
else
    write_out "b" "Running ACTION...\n"
    # shellcheck disable=SC1091
    . "${ACTION_PARENT_DIR}"/entry/run_action.sh
    write_out "b" "Action Complete"
fi
