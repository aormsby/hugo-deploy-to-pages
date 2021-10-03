#!/bin/sh

# shellcheck disable=SC1091
# config git settings
. "${ACTION_PARENT_DIR}"/run/config_git.sh
config_for_action

# checkout release branch
. "${ACTION_PARENT_DIR}"/run/checkout.sh
checkout_release_branch
checkout_submodule_branch

# build data io functions
. "${ACTION_PARENT_DIR}"/run/io_build_data.sh
read_build_data

# merge from source to release branch
if [ "${IS_NEW_BRANCH}" = true ]; then
    write_out "b" "New branch created, nothing to merge. Skipping merge step."
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

# build site
. "${ACTION_PARENT_DIR}"/run/hugo_build.sh
build_site

# update data after successful build
update_build_data
write_build_data

# build site
. "${ACTION_PARENT_DIR}"/run/deploy.sh
set_commit_message

# submodule project
if [ "${PUBLISH_TO_SUBMODULE}" = true ]; then
    commit_submodule_with_message
fi

# root project
commit_with_message

if [ "${INPUT_TAG_RELEASE}" = true ]; then
    tag_release
fi

deploy_to_remote

# git config cleanup for workflow continuation
# function from config_git.sh
reset_git_config

# output 'was_new_build_created' value as true on successful new build
echo "::set-output name=was_new_build_created::true"
