#!/bin/sh

check_for_duplicate_build() {
    # early exit if build has already been made
    # if [ "${LAST_HASH}" = "${CURRENT_SOURCE_HEAD}" ]; then
    if [ "${LAST_HASH}" = "${GITHUB_SHA}" ]; then
        write_out 0 'No new changes in source branch. Skipping this build and exiting gracefully.'
    fi
}

merge_from_source() {
    # shellcheck disable=SC2086
    # --no-commit to make custom commit message and simplify number of commits in the process
    git merge ${INPUT_MERGE_ARGS} --allow-unrelated-histories --no-commit "${INPUT_SOURCE_BRANCH}"
    COMMAND_STATUS=$?

    if [ "${COMMAND_STATUS}" != 0 ]; then
        # exit on source branch merge fail
        write_out "${COMMAND_STATUS}" "Source changes could not be merged into the release branch. Check 'merge_args' input and try again."
    fi
    
    write_out -1 "Source changes merged into release branch"
    write_out "g" "SUCCESS\n"
}
