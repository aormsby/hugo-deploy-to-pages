#!/bin/sh

# source test scripts, then run individual functions
# shellcheck disable=SC1091

. "${ACTION_PARENT_DIR}"/test/verify_git_config.sh
test_config_git

. "${ACTION_PARENT_DIR}"/test/verify_branches.sh
test_source_branch_exists
test_release_branch_exists

if [ "${INPUT_FULL_REBUILD}" = true ]; then
    . "${ACTION_PARENT_DIR}"/test/verify_full_rebuild.sh
    print_regex_patterns
    print_files_to_save
    print_files_to_delete
else
    write_out "b" "'full_rebuild' not enabled. Skipping tests.\n"
fi

. "${ACTION_PARENT_DIR}"/test/verify_submodule.sh
verify_publish_submodule
verify_submodule_cloned
verify_submodule_branch_exists
