#!/bin/sh

### TODO: switch to deploy branch, merge from source branch (force/rebase?), then build?

# set local env vars here
if [ !"${GITHUB_ACTIONS}" ]; then
    INPUT_DEPLOY_BRANCH="test2"
    INPUT_SOURCE_BRANCH="master"
fi

# region script vars
# vars used by script, do no edit
FRESH="${INPUT_FRESH_BUILD}"
IGNORE_FILES=". .. .git CNAME ${INPUT_DO_NOT_DELETE_FILES}" # space-delimited array of files to protect when 'fresh' option is used
DEPLOY_TO_SUBMODULE="false" # false by default, set to true if input_deploy_directory matches a repo submodule

# console text styles
S_LY="\033[93m"
S_LR="\033[91m"
S_N="\033[m"
S_B="\033[1m"
S_LG="\033[32m"
# endregion

# region script functions
configure_git_user() {
    git config --global user.name "${INPUT_GIT_EMAIL}"
    git config --global user.email "${INPUT_GIT_USER}"
}

check_for_deploy_submodule() {
    # checks if the .gitmodules file contains a submodule at the deploy directory path
    TARGET_REPO_SUBMODULE=$(git config --file .gitmodules --get-regexp path | grep "${INPUT_DEPLOY_DIRECTORY}$" )
    if [ -n "${TARGET_REPO_SUBMODULE}" ]; then
        DEPLOY_TO_SUBMODULE="true"
    fi
}

# retrieve last commit hash from hugo-deploy.dat
read_build_data() {
	if [ -f "hugo-deploy.dat" ]; then
		BUILD_NUMBER=$(($(head -1 hugo-deploy.dat) + 1))
		LAST_HASH=$(tail -1 hugo-deploy.dat)
    else
		BUILD_NUMBER=1
        LAST_HASH=0
	fi

	# if [ ! -f "build.dat" ]; then
	# 	BUILD_NUMBER=1
	# else
	# 	BUILD_NUMBER=$(($(cat build.dat) + 1))
	# fi
}

set_commit_message() {

    COMMIT_MESSAGE="auto-build #${BUILD_NUMBER} - ${INPUT_SOURCE_BRANCH} @ ${SOURCE_HASH}"

    if [ -n "${INPUT_COMMIT_MESSAGE}" ]; then
        COMMIT_MESSAGE="${COMMIT_MESSAGE}\n\n${INPUT_COMMIT_MESSAGE}"
    fi
	echo "${COMMIT_MESSAGE}"
}

# update build number before operation begins
write_build_data() {
	# store build number in hugo-deploy.dat
	echo "${BUILD_NUMBER}\n${SOURCE_HASH}" >hugo-deploy.dat || fail_and_exit "warn" "build number update" "Build number could not be updated for some reason. Process may have completed anyway."
}

# make sure the active local branches match the settings (and exit if they can't be switched to)
check_branches() {
	# ensure source branch exists, fail if it doesn't
	SOURCE_CHECK=$(git branch --list "${INPUT_SOURCE_BRANCH}")
	if [ -z "${SOURCE_CHECK}" ]; then
		fail_and_exit "error" "branch check" "Source branch '${INPUT_SOURCE_BRANCH}' could not be found."
	fi

    # ensure correct deploy branch is checked out, create if it doesn't exist
    if [ $(git branch --show-current) != "${INPUT_DEPLOY_BRANCH}" ]; then
        git fetch origin ${INPUT_DEPLOY_BRANCH}
		
		git checkout ${INPUT_DEPLOY_BRANCH} || \
			(echo "Creating new branch '${INPUT_DEPLOY_BRANCH}'" && git checkout -b ${INPUT_DEPLOY_BRANCH}) || \
				fail_and_exit "error" "branch check" "Repo failed to switch to branch '${INPUT_DEPLOY_BRANCH}'."
    fi
    # echo "Build branch '${INPUT_DEPLOY_BRANCH}' checked out" 1>&1

    #________#_#_#_#_#_#_#_

    # ensure correct build branch is checked out
    # if [ $(git branch --show-current) != "${INPUT_BUILD_BRANCH}" ]; then
    #     git fetch origin ${INPUT_BUILD_BRANCH}
    #     git checkout ${INPUT_BUILD_BRANCH} || fail_and_exit "error" "branch check" "Repo failed to switch to branch '${INPUT_BUILD_BRANCH}'. Does it exist?"
    #     # echo "Build branch '${INPUT_BUILD_BRANCH}' checked out" 1>&1
    # fi

    # ### TODO: change 'deploy branch' to... something else like 'submodule branch'

    # # if using submodule, ensure target deploy branch is checked out
    # if [ "${DEPLOY_TO_SUBMODULE}" = "true" ]; then
    #     # set fetch spec to get all remote heads for the deploy submodule, not limited to what the checkout sets
    #     git -C ${INPUT_DEPLOY_DIRECTORY} config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"

    #     #sync and update the deploy submodule
    #     git submodule sync --recursive ${INPUT_DEPLOY_DIRECTORY}
    #     git submodule update --init --recursive --remote ${INPUT_DEPLOY_DIRECTORY}

    #     # checkout specified submodule deploy branch
    #     git -C ${INPUT_DEPLOY_DIRECTORY} checkout ${INPUT_DEPLOY_BRANCH} || fail_and_exit "error" "branch check" "Submodule repo failed to switch to branch '${INPUT_DEPLOY_BRANCH}'. Does it exist?"
    #     # echo "Deploy branch '${INPUT_DEPLOY_BRANCH}' checked out" 1>&1
    # fi
}

# on 'fresh', delete public data before rebuild (ignores files by name from settings 'array')
clear_pub_data() {
    # display ignored files
    echo "'Fresh' option enabled. Deleting previous build files." 1>&1
    for i in $(echo "${IGNORE_FILES}" | sed "s/ /\\ /g"); do
		echo "ignored : ${i}"
	done
    unset i

	# get string of filenames at submodule path
	FILE_LIST=$(ls -a "${INPUT_DEPLOY_DIRECTORY}")

	# remove the ignored filenames from the string list
	for i in $(echo "${IGNORE_FILES}" | sed "s/ /\\ /g"); do
		FILE_LIST=$(echo "${FILE_LIST}" | sed "s/^${i}$/\\ /g")
	done
	unset i

	# delete remaining files in the filename list
	for i in $(echo "${FILE_LIST}" | sed "s/ /\\ /g"); do
        echo "deleted => ${i}"
		rm -r "${INPUT_DEPLOY_DIRECTORY:?}/${i}"
	done
	unset i

    echo "'Fresh' file deletion complete" 1>&1
}

# 'hugo build' plus any optional arguments
build_site() {
    echo "running command: hugo ${INPUT_HUGO_BUILD_OPTIONS}"
	hugo "${INPUT_HUGO_BUILD_OPTIONS}" || fail_and_exit "error" "hugo" "Hugo build failed. Check output for details."
}

# add, commit, and push, baby!
deploy_to_remote() {
    # add and commit deploy module
    if [ "${DEPLOY_TO_SUBMODULE}" = "true" ]; then
        git -C ${INPUT_DEPLOY_DIRECTORY} add . || fail_and_exit "error" "git add files to submodule deploy repo" "Files could not be staged for some reason."
	    git -C ${INPUT_DEPLOY_DIRECTORY} commit -m "${COMMIT_MESSAGE}" || fail_and_exit "safe" "git commit to submodule deploy repo" "No changes from build. Nothing to commit. Exiting without deploy."
        git -C ${INPUT_DEPLOY_DIRECTORY} push --recurse-submodules=on-demand || fail_and_exit "error" "git push and deploy" "Unable to push build. See output for details."
        # push to deploy submodule before the main repo to ensure the referenced commit is updated
        # HACK: For whatever reason, a normal 'push --recurse-submodules=on-demand' from the main repo fails when main repo 
        # and submodule branch names don't match. It's a frustrating result of using Github's checkout action. But this is an okay workaround.

        # add and commit only the deploy directory to the main module - updates the submodule hash
        git add ${INPUT_DEPLOY_DIRECTORY} || fail_and_exit "error" "git add files to main build repo" "Files could not be staged for some reason."
	    git commit -m "${COMMIT_MESSAGE}" || fail_and_exit "safe" "git commit to main build repo" "No changes from build. Nothing to commit. Exiting without deploy."
    else
        # add all changes if no deploy submodule
        git add . || fail_and_exit "error" "git add files to main build repo" "Files could not be staged for some reason."
	    git commit -m "${COMMIT_MESSAGE}" || fail_and_exit "safe" "git commit to main build repo" "No changes from build. Nothing to commit. Exiting without deploy."  
    fi

    # push main repo and any changed submodules (apart from deploy repo)
	git push --recurse-submodules=on-demand || fail_and_exit "error" "git push and deploy" "Unable to push build. See output for details."
}

# exit with a console message on any failed action
fail_and_exit() {
    case "${1}" in
        "warn")     EXIT_LOG=$(printf "%s%s" "\n" "${S_B}${S_LY}WARNING:${S_N}")    ;;
        "error")    EXIT_LOG=$(printf "%s%s" "\n" "${S_B}${S_LR}ERROR:${S_N}")      ;;
        "safe")     EXIT_LOG=$(printf "%s%s" "\n" "${S_B}${S_LG}SAFE EXIT:${S_N}")      ;;
    esac

    EXIT_LOG=$(printf "%s%s" "${EXIT_LOG} Deploy process exited during '${2}' step. ${3}" "\n")

	echo "${EXIT_LOG}" 1>&1
	close_build_data "revert"

    if [ "${1}" = "safe" ]; then
        exit 0
    fi

	exit 1
}
# endregion

# region main script
####################################################################
# Main script starts here

# set commit credentials
configure_git_user

# check if we're deploying to a submodule
check_for_deploy_submodule

# make sure the active local branches match the settings (and exit if they don't)
### TODO: change input to 'source branch' and 'deploy branch', change/create branches for building
check_branches

# retrieve build number from build.dat and update value before operation begins
read_build_data
check_source_commits

merge_from_source

# on 'fresh', delete public data before rebuild (ignores files by name from settings 'array')
if [ "${FRESH}" = "true" ]; then
	clear_pub_data
fi

# 'hugo build' plus any optional arguments
build_site
# set commit message using deploy data
set_commit_message


# add, commit, and push, baby!
deploy_to_remote

# write new build data on successful deploy
write_build_data
# endregion

# TODO: @v2 => pull site repo, create a new 'build branch', and build from there? to avoid pushing to the main branch?
