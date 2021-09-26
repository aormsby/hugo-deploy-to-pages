#!/bin/sh

# shellcheck disable=SC1091
# config git settings
. "${ACTION_PARENT_DIR}"/run/config_git.sh
config_for_action

# git config cleanup for workflow continuation
# function from config_git.sh
reset_git_config