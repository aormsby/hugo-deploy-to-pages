#!/bin/sh

AUTO_COMMIT_DEFAULT_HEADER="Action auto-build #${LAST_BUILD_NUMBER}"
AUTO_COMMIT_MESSAGE_BODY=$(printf '%s,\n%s,\n%s,\n%s' "${AUTO_COMMIT_DEFAULT_HEADER}" "Built from branch '${INPUT_SOURCE_BRANCH}'" "Source commit hash '${LAST_SOURCE_HASH}'" "Source commit time '${LAST_SOURCE_BUILD_TIME}'")

set_commit_message() {
    if [ -z "${INPUT_COMMIT_MESSAGE}" ]; then
        COMMIT_MESSAGE="${AUTO_COMMIT_DEFAULT_HEADER}"
    else
        COMMIT_MESSAGE="${INPUT_COMMIT_MESSAGE}"
    fi

    COMMIT_MESSAGE=$(printf '%s\n\n%s' "${COMMIT_MESSAGE}" "${AUTO_COMMIT_MESSAGE_BODY}")
}

commit_build() {
    #submodule first
    if [ "${PUBLISH_TO_SUBMODULE}" = true ]; then
        commit_with_message "${INPUT_HUGO_PUBLISH_DIRECTORY}"
    fi

    # root project
    commit_with_message "."
}

commit_with_message() {
    # required steps to include all changes
    git -C "${1}" add --all
    git -C "${1}" commit -m "${COMMIT_MESSAGE}"
    COMMAND_STATUS=$?

    if [ "${COMMAND_STATUS}" != 0 ]; then
        # safe exit on git commit fail, but with warning
        write_out "y" "Git commit step failed in '${1}' directory. It's possible there were no changes to commit, so a safe exit is assumed."
        write_out 0 'No changes since last build. Exiting gracefully.'
    fi
}

tag_release() {
    write_out -1 "Tagging release with build number." 1>&1
    git tag -a "auto-${LAST_BUILD_NUMBER}" -m "Auto-build #${LAST_BUILD_NUMBER}"
}

deploy_to_remote() {
    #submodule first
    # can always use --set-upstream because if branch already exists it does nothing
    if [ "${PUBLISH_TO_SUBMODULE}" = true ]; then
        git -C "${INPUT_HUGO_PUBLISH_DIRECTORY}" push --set-upstream --recurse-submodules=on-demand --follow-tags origin "${INPUT_SUBMODULE_RELEASE_BRANCH}"
        COMMAND_STATUS=$?

        if [ "${COMMAND_STATUS}" != 0 ]; then
            # exit on push fail
            write_out "${COMMAND_STATUS}" "Unable to push commit to submodule branch '${INPUT_SUBMODULE_RELEASE_BRANCH}'. Check output and try again."
        fi

        write_out "b" "Push to submodule branch complete"
    fi

    # root projet
    # can always use --set-upstream because if branch already exists it does nothing
    git push --set-upstream --recurse-submodules=on-demand --follow-tags origin "${INPUT_RELEASE_BRANCH}"
    COMMAND_STATUS=$?

    if [ "${COMMAND_STATUS}" != 0 ]; then
        # exit on push fail
        write_out "${COMMAND_STATUS}" "Unable to push commit to branch '${INPUT_RELEASE_BRANCH}'. Check output and try again."
    fi

    write_out "b" "Push to release branch complete"
    write_out "g" "SUCCESS\n"
}
