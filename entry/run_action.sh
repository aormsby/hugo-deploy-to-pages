#!/bin/sh

# shellcheck disable=SC1091
# config git settings
. "${ACTION_PARENT_DIR}"/run/config_git.sh
config_for_action

# checkout release branch
. "${ACTION_PARENT_DIR}"/run/checkout_branch.sh
checkout

# build data io functions
. "${ACTION_PARENT_DIR}"/run/io_build_data.sh
read_build_data

# merge from source to release branch
if [ "${IS_NEW_BRANCH}" = true ]; then
        write_out -1 "New branch created, nothing to merge. Skipping merge step."
else
    . "${ACTION_PARENT_DIR}"/run/merge_branch.sh
    merge_from_source
fi

# git config cleanup for workflow continuation
# function from config_git.sh
reset_git_config
