#!/bin/sh

# check to see if the publish directory is a git submodule
verify_publish_submodule() {
    write_out "y" "TEST"
    write_out -1 "Verify if publish directory '${INPUT_HUGO_PUBLISH_DIRECTORY}' contains a git submodule."

    if [ -f ".gitmodules" ]; then
        SUBMODULE_PATH=$(git config -f .gitmodules --get-regexp "${INPUT_HUGO_PUBLISH_DIRECTORY}" | grep -e "\.path" | cut -d" " -f2)
        if [ "${SUBMODULE_PATH}" = "${INPUT_HUGO_PUBLISH_DIRECTORY}" ]; then
            write_out "g" "PASSED - '${INPUT_HUGO_PUBLISH_DIRECTORY}' publish directory confirmed as a git submodule. Release will be published to the submodule.\n"
            PUBLISH_TO_SUBMODULE=true
        else
            write_out "b" "'${INPUT_HUGO_PUBLISH_DIRECTORY}' is not a git submodule. Action will skip submodule steps.\n"
            PUBLISH_TO_SUBMODULE=false
        fi
    else
        write_out "b" "No '.gitmodules' file found. Will not publish release build to a submodule.\n"
        PUBLISH_TO_SUBMODULE=false
    fi
}

# if publish directory is a submodule, make sure it was cloned by actions/checkout step
verify_submodule_cloned() {
    write_out "y" "TEST"
    write_out -1 "Verify git submodule in '${INPUT_HUGO_PUBLISH_DIRECTORY}' was properly cloned."

    if [ "${PUBLISH_TO_SUBMODULE}" = true ]; then
        DIR_CONTENTS=$(ls "${INPUT_HUGO_PUBLISH_DIRECTORY}")
        if [ -z "${DIR_CONTENTS}" ]; then
            write_out "r" "FAILED - '${INPUT_HUGO_PUBLISH_DIRECTORY}' is empty. Did you include 'submodules: recursive' in the 'action/checkout' step?\n"
            SUBMODULE_CLONED=false
        else
            write_out "g" "PASSED - Contents found in '${INPUT_HUGO_PUBLISH_DIRECTORY}'. Submodule was checked out properly.\n"
            SUBMODULE_CLONED=true
        fi
    else
        write_out "b" "Publish directory not marked as submodule. Skipping test.\n"
        SUBMODULE_CLONED=false
    fi

}

verify_submodule_branch_exists() {
    # Make check in submodule repo for submodule deploy branch
    write_out "y" "TEST"
    write_out -1 "[Verify Submodule Branch] -> tests 'submodule_release_branch' input"

    if [ "${SUBMODULE_CLONED}" = true ]; then
        git -C "${INPUT_HUGO_PUBLISH_DIRECTORY}" fetch --quiet --depth=1 origin "refs/heads/${INPUT_SUBMODULE_RELEASE_BRANCH}"
        VERIFY_SUBMODULE_RELEASE_BRANCH=$(git rev-parse --verify "remotes/origin/${INPUT_SUBMODULE_RELEASE_BRANCH}")

        if [ -z "${VERIFY_SUBMODULE_RELEASE_BRANCH}" ]; then
            write_out "y" "WARNING - no branch '${INPUT_SUBMODULE_RELEASE_BRANCH}' found in the publish submodule.\nA new branch will be created when you run the action. Please make sure you want this.\n"
        else
            write_out "g" "PASSED\n"
        fi
    else
        write_out "b" "Submodule not cloned with action/checkout step. Skipping test.\n"
    fi
}
