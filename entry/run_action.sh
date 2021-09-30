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
    check_for_duplicate_build
    merge_from_source
fi

# clear build directory if required
if [ "${INPUT_FULL_REBUILD}" = true ]; then
    . "${ACTION_PARENT_DIR}"/run/rebuild.sh
    clean_output_directory
fi

# # build site
# . "${ACTION_PARENT_DIR}"/run/hugo_build.sh
# build_site

# # update data after successful build
# update_build_data
# write_build_data

# # build site
# . "${ACTION_PARENT_DIR}"/run/deploy.sh
# commit_with_message
# deploy_to_remote

# # git config cleanup for workflow continuation
# # function from config_git.sh
# reset_git_config
