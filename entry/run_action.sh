#!/bin/sh

# shellcheck disable=SC1091
# config git settings
. "${ACTION_PARENT_DIR}"/run/config_git.sh
config_for_action

# checkout release branch
. "${ACTION_PARENT_DIR}"/run/checkout_branches.sh
checkout_release_branch

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

# actually check out submodule branch after getting a clean merge
if [ "${PUBLISH_TO_SUBMODULE}" = true ]; then
    checkout_submodule_branch
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
commit_build

if [ "${INPUT_TAG_RELEASE}" = true ]; then
    tag_release
fi

deploy_to_remote

# git config cleanup for workflow continuation
# function from config_git.sh
reset_config_after_action

# output 'was_new_build_created' value as true on successful new build
echo "::set-output name=was_new_build_created::true"
