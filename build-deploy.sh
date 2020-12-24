#!/bin/sh

# IGNORE - set env vars here for local testing only
if [ ! "${GITHUB_ACTIONS}" ]; then
    INPUT_DEPLOY_BRANCH="test3"
	INPUT_SOURCE_BRANCH="master"
    INPUT_SUBMODULE_BRANCH="test3"
    INPUT_HUGO_BUILD_DIRECTORY="public"
	# INPUT_COMMIT_MESSAGE="insert commit message here"
	# SOURCE_HASH="jfkdlf"
fi

# region script vars
# vars used by script, do no edit
FRESH="${INPUT_FRESH_BUILD}"
# TODO: set CNAME as DnD files for input input, leave dotfiles here
IGNORE_FILES=". .. .git CNAME ${INPUT_DO_NOT_DELETE_FILES}" # space-delimited array of files to protect when input_fresh_build option is set to true
DEPLOY_TO_SUBMODULE="false" # false by default, set to true if input_submodule_branch is set

# console text styles
S_LY="\033[93m"
S_LR="\033[91m"
S_N="\033[m"
S_B="\033[1m"
S_LG="\033[32m"
# endregion

# TODO: update to match fork sync
# region script functions
configure_git_user() {
    git config --global user.name "${INPUT_GIT_EMAIL}"
    git config --global user.email "${INPUT_GIT_USER}"
}

# enables future processes based on user's input_submodule_branch value
check_for_deploy_submodule() {
    if [ "${INPUT_SUBMODULE_BRANCH}" != "" ]; then
        DEPLOY_TO_SUBMODULE="true"
    fi
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
		git fetch origin "${INPUT_DEPLOY_BRANCH}"
		
		git checkout "${INPUT_DEPLOY_BRANCH}" || \
			(echo "Creating new branch '${INPUT_DEPLOY_BRANCH}'" && \
            git checkout -b "${INPUT_DEPLOY_BRANCH}") || \
				fail_and_exit "error" "branch check" "Repo failed to switch to branch '${INPUT_DEPLOY_BRANCH}'."
    fi
    # echo "Build branch '${INPUT_DEPLOY_BRANCH}' checked out" 1>&1

    # ensure correct sumbmodule branch is checked out, create if it doesn't exist
    if [ "${DEPLOY_TO_SUBMODULE}" = "true" ]; then
        CUR_BRANCH=$(git -C "${INPUT_HUGO_BUILD_DIRECTORY}" branch --show-current)
        if [ "${CUR_BRANCH}" != "${INPUT_SUBMODULE_BRANCH}" ]; then
            git -C "${INPUT_HUGO_BUILD_DIRECTORY}" fetch origin "${INPUT_SUBMODULE_BRANCH}"
            
            git -C "${INPUT_HUGO_BUILD_DIRECTORY}" checkout "${INPUT_SUBMODULE_BRANCH}" || \
                (echo "Creating new submodule branch '${INPUT_SUBMODULE_BRANCH}'" && \
                git -C "${INPUT_HUGO_BUILD_DIRECTORY}" checkout -b "${INPUT_SUBMODULE_BRANCH}") || \
                    fail_and_exit "error" "submodule branch check" "Submodule failed to switch to branch '${INPUT_SUBMODULE_BRANCH}'."
        fi
    fi
}

# retrieve last build data from hugo-deploy.dat
read_build_data() {
	if [ -f "hugo-deploy.dat" ]; then
		BUILD_NUMBER=$(($(head -1 hugo-deploy.dat) + 1))
		LAST_HASH=$(tail -1 hugo-deploy.dat)
    else
        BUILD_NUMBER=1
        LAST_HASH=0
	fi
}

# if no new commits, exit deploy process safely
check_source_commits() {
	SOURCE_HASH=$(git show-ref --hash --abbrev "heads/${INPUT_SOURCE_BRANCH}")
    
	# no previous deploys, continue with process
	if [ "${LAST_HASH}" = 0 ]; then
		return
	fi
	
	if [ "${SOURCE_HASH}" = "${LAST_HASH}" ]; then
		fail_and_exit "safe" "check for new source commits" "Previously built from the latest commit on source branch. Exiting without deploy."
	fi
}

# TODO: consider a recursive Xtheirs to ensure source overrides any conflicts that appear in deploy branch
# pull source data into deploy branch to prep for new build
merge_from_source() {
	git merge ${INPUT_SOURCE_MERGE_ARGS} "${INPUT_SOURCE_BRANCH}" --no-commit || fail_and_exit "error" "merge" "Source data could not be merged to the deploy branch. Check status and try again."
}

# in input_fresh_build is true, delete previous build outpu before rebuild (ignores files in input_do_not_delete_files)
clear_pub_data() {
    # display ignored files
    echo "'Fresh' option enabled. Deleting previous build files." 1>&1
    for i in $(echo "${IGNORE_FILES}" | sed "s/ /\\ /g"); do
		echo "ignored : ${i}"
	done
    unset i

	# get string of filenames at submodule path
	FILE_LIST=$(ls -a "${INPUT_HUGO_BUILD_DIRECTORY}")

	# remove the ignored filenames from the string list
	for i in $(echo "${IGNORE_FILES}" | sed "s/ /\\ /g"); do
		FILE_LIST=$(echo "${FILE_LIST}" | sed "s/^${i}$/\\ /g")
	done
	unset i

	# delete remaining files in the filename list
	for i in $(echo "${FILE_LIST}" | sed "s/ /\\ /g"); do
        echo "deleted => ${i}"
		rm -r "${INPUT_HUGO_BUILD_DIRECTORY:?}/${i}"
	done
	unset i

    echo "'Fresh' file deletion complete" 1>&1
}

# set commit message based on commit hash and hugo-deploy.dat
set_commit_message() {
    COMMIT_MESSAGE="auto-build #${BUILD_NUMBER} - ${INPUT_SOURCE_BRANCH} @ ${SOURCE_HASH}"

    if [ -n "${INPUT_COMMIT_MESSAGE}" ]; then
        COMMIT_MESSAGE="${COMMIT_MESSAGE}" "\n\n" "${INPUT_COMMIT_MESSAGE}"
    fi
	echo "${COMMIT_MESSAGE}"
}

# run 'hugo build' plus any input_hugo_build_options
build_site() {
    echo "running command: hugo ${INPUT_HUGO_BUILD_OPTIONS}"
	hugo "${INPUT_HUGO_BUILD_OPTIONS}" || fail_and_exit "error" "hugo" "Hugo build failed. Check output for details."
}

# add, commit, and push, baby!
deploy_to_remote() {
    # add and commit deploy module
    if [ "${DEPLOY_TO_SUBMODULE}" = "true" ]; then
        git -C ${INPUT_HUGO_BUILD_DIRECTORY} add . || fail_and_exit "error" "git add files in submodule" "Files could not be staged in the deploy submodule for some reason."
	    git -C ${INPUT_HUGO_BUILD_DIRECTORY} commit -m "${COMMIT_MESSAGE}" || fail_and_exit "safe" "git commit in submodule" "No changes from build. Nothing to commit. Exiting without deploy."
        git -C ${INPUT_HUGO_BUILD_DIRECTORY} push -u origin "${INPUT_SUBMODULE_BRANCH}" --recurse-submodules=on-demand || fail_and_exit "error" "git push in submodule" "Unable to push build from deploy submodule. See git output for details."
        
        # push to deploy submodule before the main repo to ensure the referenced commit is updated
        # HACK: For whatever reason, a normal '--recurse-submodules=on-demand' from the main repo fails when main repo 
        # and submodule branch names don't match. It's a frustrating result of using Github's checkout action, but this is a good workaround.
    fi
    
    # add all changes to base repo (the only repo if not using submodules) and push all
    git add . || fail_and_exit "error" "git add files in root dir" "Files could not be staged in the root directory for some reason."
    git commit -m "${COMMIT_MESSAGE}" || fail_and_exit "safe" "git commit in root die" "No changes from build. Nothing to commit. Exiting without deploy."  
	git push -u origin "${INPUT_DEPLOY_BRANCH}" --recurse-submodules=on-demand || fail_and_exit "error" "git push in root dir" "Unable to push build from root directory. See output for details."
}

# write new build data to hugo-deploy.dat on successful deploy
write_build_data() {
	echo "${BUILD_NUMBER}\n${SOURCE_HASH}" >hugo-deploy.dat || fail_and_exit "warn" "build number update" "Build number could not be updated for some reason. Process may have completed anyway."
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

# make sure the active local branches match the settings (and exit if they can't be switched to)
check_branches

# retrieve last build data from hugo-deploy.dat
read_build_data

# if no new commits, exit deploy process safely
check_source_commits

# pull source data into deploy branch to prep for new build
merge_from_source

# in input_fresh_build is true, delete previous build outpu before rebuild (ignores files in input_do_not_delete_files)
if [ "${FRESH}" = "true" ]; then
	clear_pub_data
fi

# set commit message based on commit hash and hugo-deploy.dat
set_commit_message

# run 'hugo build' plus any input_hugo_build_options
build_site

# add, commit, and push, baby!
deploy_to_remote

# write new build data to hugo-deploy.dat on successful deploy
write_build_data
# endregion
