#!/bin/sh

# checkout release branch, create if it doesn't exist
checkout() {
    write_out -1 "Checking out release branch '${INPUT_RELEASE_BRANCH}' for deploy."

    git fetch --depth=1 --recurse-submodules=on-demand origin "refs/heads/${INPUT_RELEASE_BRANCH}"
    COMMAND_STATUS=$?

    if [ "${COMMAND_STATUS}" != 0 ]; then
        # branch not found, create it from the source branch
        write_out -1 "Release branch not found, creating new release branch '${INPUT_RELEASE_BRANCH}' for deploy."
        git checkout -b "${INPUT_RELEASE_BRANCH}"
        COMMAND_STATUS=$?
    else
        # release branch found, checkout branch
        git checkout --recurse-submodules "${INPUT_RELEASE_BRANCH}"
        COMMAND_STATUS=$?
    fi

    if [ "${COMMAND_STATUS}" != 0 ]; then
        # exit on branch checkout fail
        write_out "${COMMAND_STATUS}" "Release branch '${INPUT_RELEASE_BRANCH}' could not be checked out."
    fi

    write_out -1 "Release branch checked out"
    write_out "g" "SUCCESS\n"
}
