#!/bin/sh

test_source_branch_exists() {
    write_out "y" "TEST"
    write_out -1 "[Verify Source Branch] -> tests 'source_branch' input"
    VERIFY_SOURCE_BRANCH=$(git rev-parse --verify "remotes/origin/${INPUT_SOURCE_BRANCH}")

    if [ -z "${VERIFY_SOURCE_BRANCH}" ]; then
        write_out "r" "FAILED - no branch '${INPUT_SOURCE_BRANCH}' found\nDid you set 'ref' correctly in the checkout step? It should match the source branch.\n"
    else
        write_out "g" "PASSED\n"
    fi
}

test_release_branch_exists() {
    write_out "y" "TEST"
    write_out -1 "[Verify Release Branch] -> tests 'release_branch' input"

    git fetch --quiet --depth=1 origin "refs/heads/${INPUT_RELEASE_BRANCH}"
    VERIFY_RELEASE_BRANCH=$(git rev-parse --verify "remotes/origin/${INPUT_RELEASE_BRANCH}")

    if [ -z "${VERIFY_RELEASE_BRANCH}" ]; then
        write_out "y" "WARNING - no branch '${INPUT_RELEASE_BRANCH}' found\nA new branch will be created when you run the action. Please make sure you want this.\n"
    else
        write_out "g" "PASSED\n"
    fi

}

# TODO: write submodule test
test_submodule_exists() {
    # Maybe I can check git submodule refs instead of having an input for the submodule directory
    true
}

# TODO: write submodule branch test
test_submodule_deploy_branch_exists() {
    # Make check in submodule repo for submodule deploy branch
    true
}
