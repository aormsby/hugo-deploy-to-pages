#!/bin/sh

check_for_duplicate_build() {
    # early exit if build has already been made
    if [ "${LAST_HASH}" = "${GITHUB_SHA}" ]; then
        write_out 0 'No changes since last build. Exiting gracefully.'
    fi
}

merge_from_source() {
    write_out -1 "Merging from '${INPUT_SOURCE_BRANCH}' to '${INPUT_RELEASE_BRANCH}' with merge args '${INPUT_MERGE_ARGS}'"
    
    # shellcheck disable=SC2086
    # --no-commit to make custom commit message and simplify number of commits in the process
    git merge ${INPUT_MERGE_ARGS} --allow-unrelated-histories --no-commit "${INPUT_SOURCE_BRANCH}"
    COMMAND_STATUS=$?
    
    # first pass - try to checkout --theirs on all unmerged items (-U) when using default merge args
    if [ "${COMMAND_STATUS}" != 0 ]; then # &&
        # [ "${INPUT_MERGE_ARGS}" = "-s recursive -Xtheirs" ]; then
        write_out "y" "Unable to automatically merge some conflicts. (Expected with submodules in particular.) Using a simple resolve to move forward."
        
        # manually checkout 'theirs' on conflict items
        CONFLICT_ITEMS=$(git diff --name-only --diff-filter=U)

        for item in ${CONFLICT_ITEMS}; do
            git checkout --theirs "${item}"
        done
        COMMAND_STATUS=$?
    fi

    # second pass - actual failure
    if [ "${COMMAND_STATUS}" != 0 ]; then
        # exit on source branch merge fail
        write_out "${COMMAND_STATUS}" "Source changes could not be merged into the release branch. Maybe check 'merge_args' input and try again."
    fi
    
    write_out -1 "Source changes merged into release branch"
    write_out "g" "SUCCESS\n"
}
