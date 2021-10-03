#!/bin/sh

# check to see if the publish directory is a git submodule
verify_publish_submodule() {
    write_out "y" "Checking if '${INPUT_HUGO_PUBLISH_DIRECTORY}' is a git submodule."

    if [ -f ".gitmodules" ]; then
        SUBMODULE_PATH=$(git config -f .gitmodules --get-regexp "${INPUT_HUGO_PUBLISH_DIRECTORY}" | grep -e "\.path" | cut -d" " -f2)
        if [ "${SUBMODULE_PATH}" = "${INPUT_HUGO_PUBLISH_DIRECTORY}" ]; then
            write_out "g" "'${INPUT_HUGO_PUBLISH_DIRECTORY}' publish directory confirmed as a git submodule. Release will be published to the submodule."
            PUBLISH_TO_SUBMODULE=true
        else
            write_out "b" "'${INPUT_HUGO_PUBLISH_DIRECTORY}' not found in git submodule paths. Action will skip submodule steps."
            PUBLISH_TO_SUBMODULE=false
        fi
    else
        PUBLISH_TO_SUBMODULE=false
        write_out "b" "No '.gitmodules' file found. Will not publish release build to a submodule."
    fi
}

# if publish directory is a submodule, make sure it was checked out by actions/checkout step
verify_submodule_checkout() {
    write_out "y" "Checking if '${INPUT_HUGO_PUBLISH_DIRECTORY}' was properly checked out as a submodule."

    if [ "${PUBLISH_TO_SUBMODULE}" = true ]; then
        DIR_CONTENTS=$(ls "${INPUT_HUGO_PUBLISH_DIRECTORY}")
        if [ -z "${DIR_CONTENTS}" ]; then
            write_out "r" "'${INPUT_HUGO_PUBLISH_DIRECTORY}' is empty. Did you include 'submodules: recursive' in the 'action/checkout' step?"
            write_out "b" "(Ignore this error if the '${INPUT_HUGO_PUBLISH_DIRECTORY}' directory has not been created yet.)"
        else
            write_out "g" "Contents found in '${INPUT_HUGO_PUBLISH_DIRECTORY}'. Submodules are being checked out properly."
        fi
    else
        write_out "b" "Publish directory not marked as submodule. Skipping test."
    fi

}
