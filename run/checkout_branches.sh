#!/bin/sh

# checkout release branch, create if it doesn't exist
checkout_release_branch() {
    write_out -1 "Checking out release branch '${INPUT_RELEASE_BRANCH}' for deploy."

    # TODO: solve with depth for shallow checkout
    # git fetch --depth=1 --recurse-submodules=on-demand origin "refs/heads/${INPUT_RELEASE_BRANCH}"
    git fetch --recurse-submodules=on-demand origin "refs/heads/${INPUT_RELEASE_BRANCH}"
    COMMAND_STATUS=$?

    # test command status from fetch action
    if [ "${COMMAND_STATUS}" != 0 ]; then
        # branch not found, create it from the source branch
        write_out -1 "Release branch not found, creating new release branch '${INPUT_RELEASE_BRANCH}' for deploy."
        git checkout -b "${INPUT_RELEASE_BRANCH}"
        COMMAND_STATUS=$?

        # shellcheck disable=SC2034
        IS_NEW_BRANCH=true
    else
        # release branch found, checkout branch
        git checkout --recurse-submodules "${INPUT_RELEASE_BRANCH}"
        COMMAND_STATUS=$?

        # shellcheck disable=SC2034
        IS_NEW_BRANCH=false
    fi

    # test command status from checkout action
    if [ "${COMMAND_STATUS}" != 0 ]; then
        # exit on branch checkout fail
        write_out "${COMMAND_STATUS}" "Release branch '${INPUT_RELEASE_BRANCH}' could not be checked out."
    fi

    write_out -1 "Release branch checked out."
    write_out "g" "SUCCESS\n"
}

checkout_submodule_branch() {
    write_out -1 "Checking out submodule branch '${INPUT_SUBMODULE_RELEASE_BRANCH}' for deploy.\n"

    # fetch submodule release branch
    # TODO: solve with depth for shallow checkout
    # git -C "${INPUT_HUGO_PUBLISH_DIRECTORY}" fetch --quiet --depth=1 origin "refs/heads/${INPUT_SUBMODULE_RELEASE_BRANCH}"
    git -C "${INPUT_HUGO_PUBLISH_DIRECTORY}" fetch --quiet origin "refs/heads/${INPUT_SUBMODULE_RELEASE_BRANCH}"
    COMMAND_STATUS=$?

    if [ "${COMMAND_STATUS}" != 0 ]; then
        # exit on branch fetch fail
        write_out "${COMMAND_STATUS}" "Submodule release branch '${INPUT_SUBMODULE_RELEASE_BRANCH}' could not be fetched. Check input and try again."
    fi

    # checkout submodule release branch
    git -C "${INPUT_HUGO_PUBLISH_DIRECTORY}" checkout "${INPUT_SUBMODULE_RELEASE_BRANCH}"
    COMMAND_STATUS=$?

    if [ "${COMMAND_STATUS}" != 0 ]; then
        # exit on branch checkout fail
        write_out "${COMMAND_STATUS}" "Submodule release branch '${INPUT_SUBMODULE_RELEASE_BRANCH}' could not be checked out. Check input and try again."
    fi

    write_out -1 "Submodule branch checked out."
    write_out "g" "SUCCESS\n"
}
