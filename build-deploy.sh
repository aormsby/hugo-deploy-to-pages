#!/bin/sh

# region settings
# BUILD/DEPLOY SETTINGS - edit as needed for your use case
PUB_SUBMODULE="public"         # name of output folder where git submodule is located
IGNORE_FILES=". .. .git CNAME" # space-delimited array of files to protect when 'fresh' option is used
DEV_BRANCHES="dev dev"         # development branches to build on and push to, 1-root, 2-pubmodule
PROD_BRANCHES="master master"  # production branches to build on and push to, 1-root, 2-pubmodule
# endregion

# region script vars
# vars used by script, do no edit
FRESH="false"
HUGO_OPTIONS=""
# console text styles
S_LY="\033[93m"
S_LR="\033[91m"
S_N="\033[m"
S_B="\033[1m"
S_LG="\033[32m"
# endregion

# region script functions
# retrieve build number from build.dat
get_build_data() {
	if [ ! -f "build.dat" ]; then
		BUILD_NUMBER=1
	else
		BUILD_NUMBER=$(($(cat build.dat) + 1))
	fi

	COMMIT_MESSAGE="site build and deploy #${BUILD_NUMBER}"
}

# update build number before operation begins
update_build_data() {
	# reset build number on fail
	if [ "${1}" = "revert" ]; then
		BUILD_NUMBER=$((${BUILD_NUMBER} - 1))
		echo "${BUILD_NUMBER}" >build.dat
	fi

	# store build number in build.dat
	echo "${BUILD_NUMBER}" >build.dat || fail_and_exit "warn" "Build number could not be updated for some reason."
}

# make sure the active local branches match the settings (and exit if they don't)
check_branches() {
	# set public or base module as active string
	if [ "${2}" = "public" ]; then
		SUBDIR="-C ${PUB_SUBMODULE}/"
	else
		SUBDIR=""
	fi

	# check active branch
	CURRENT_BRANCH="git ${SUBDIR} branch --show-current"
	if [ "$(${CURRENT_BRANCH})" != "${1}" ]; then
		fail_and_exit "warn" "Active ${2} branch does not match deploy settings. Switch public repo to '${1}' branch and run again."
	fi
}

# check if branches are up to date with remote (and exit if they aren't)
check_remote_status() {
	# set public or base module as active string
	if [ "${2}" = "public" ]; then
		SUBDIR="-C ${PUB_SUBMODULE}/"
	else
		SUBDIR=""
	fi

	git fetch # update local data (no merge)

	# get commit hash data from local, remote, and their common ancestor to check branch status
	A=$(git ${SUBDIR} rev-parse ${1})
	B=$(git ${SUBDIR} rev-parse origin/${1})
	C=$(git ${SUBDIR} merge-base ${1} origin/${1})

	# compare hashes, only fail if local is out of date or local and remote have diverged
	if [ "${A}" = "${B}" ]; then
		:
	elif [ "${A}" = "${C}" ]; then
		fail_and_exit "warn" "Active ${2} branch is out of date. Pull latest and try again."
	elif [ "${B}" = "${C}" ]; then
		:
	else
		fail_and_exit "warn" "Active ${2} branch is in a divergent state. Pull, resolve, and try again."
	fi
}

# on 'fresh', delete public data before rebuild (ignores files by name from settings 'array')
clear_pub_data() {
	# get string of filenames at submodule path
	FILE_LIST=$(ls -a "${PUB_SUBMODULE}/")

	# remove the ignored filenames from the string list
	for i in $(echo "${IGNORE_FILES}" | sed "s/ /\\ /g"); do
		FILE_LIST=$(echo "${FILE_LIST}" | sed "s/^${i}$/\\ /g")
	done
	unset i

	# delete remaining files in the filename list
	for f in $(echo "${FILE_LIST}" | sed "s/ /\\ /g"); do
		rm -r "${PUB_SUBMODULE:?}/${f}"
	done
	unset f
}

# 'hugo build' plus any optional arguments
build_site() {
	hugo "${HUGO_OPTIONS}" || fail_and_exit "hugo"
}

# add, commit, and push, baby!
deploy_to_remote() {
	git_add_commit "${PUB_SUBMODULE}" # add and commit files to public module
	git_add_commit                    # add and commit files to base module

	# Push base and public submodule data recursively
	git push -u origin "${BASE_BRANCH}" --recurse-submodules=on-demand || fail_and_exit "git push to remote"
}

# add and commit steps for each git module
git_add_commit() {
	# set public or base module as active string
	if [ -n "${1}" ]; then
		SUBDIR="-C ${1}/"
		WHICH="public"
	else
		SUBDIR=""
		WHICH="base"
	fi

	# git add all files
	git ${SUBDIR} add . || fail_and_exit "git add to ${WHICH} repo"

	# git commit with message
	git ${SUBDIR} commit -m "${COMMIT_MESSAGE}" || fail_and_exit "git commit to ${WHICH} repo"
}

# add custom commit message (optional)
append_commit() {
	COMMIT_MESSAGE="${COMMIT_MESSAGE} - $1"
}

# generic function for setting variables based on script options
set_variable() {
	varname=$1
	shift
	eval "$varname=\"$*\""
}

# exit with a console message on any failed action
fail_and_exit() {
	if [ "${1}" = "warn" ]; then
		EXIT_LOG=$(printf "%s%s%s" "\n" "${S_B}${S_LY}WARNING:${S_N} ${2}" "\n")
	else
		EXIT_LOG=$(printf "%s%s%s" "\n" "${S_B}${S_LR}ERROR:${S_N} Deploy process failed during '${1}' step. Fix issues and try again." "\n")
	fi

	if [ "${1}" = "git commit to public repo" ]; then
		EXIT_LOG=$(printf "%s%s%s" "${EXIT_LOG}" "(Note: Commit action will fail if there are no local changes.)" "\n")
	fi

	echo "${EXIT_LOG}"
	update_build_data "revert"
	exit 1
}

# usage printout on -h option
usage() {
	echo "$(printf "%s%s%s" "\n" "${S_B}${S_LG}USAGE:${S_N} ${0} [-d|-f] [ -m \"COMMIT_MESSAGE\" ] [ -o \"HUGO_OPTIONS\" ]" "\n")"
	echo "  -d | dev, deploys to development branches set in DEV_BRANCHES list (default is PROD_BRANCHES)"
	echo "  -f | fresh, deletes public directory data before rebuild (skips files in IGNORE_FILES list)"
	echo "  -m | message, appends auto-build commit message, works like git -m"
	echo "  -o | hugo options, includes Hugo build options during deploy process (default none)"
	echo "  -h | help and usage"
	echo "$(printf "%s%s%s" "\n" "${S_B}${S_LG}EXAMPLE:${S_N} ${0} -d -f -m \"Deploying like a rockstar!\" -o \"--cleanDestinationDir\"" "\n")"
	exit 2
}

# optional debug mode to view all output, uncomment functional to use and fill with desired tests
debug_mode() {
	echo "---TEST MODE---"
	set -x # outputs all commands called in script to the console
	# fill me out! :)
	echo "---TEST COMPLETE---"
	exit 0
}
# endregion

# region main script
####################################################################
# Main script starts here

# default values, possibly changed by 'getopts' below
BRANCH_SET="${PROD_BRANCHES}"

# retrieve build number from build.dat and update value before operation begins
get_build_data
update_build_data

# optional arguments, see 'usage' (-h)
while getopts 'dfm:o:h' c; do
	case $c in
	m) append_commit "${OPTARG}" ;;
	d) set_variable BRANCH_SET "${DEV_BRANCHES}" ;;
	f) set_variable FRESH "true" ;;
	o) set_variable HUGO_OPTIONS "${OPTARG}" ;;
	h | *)
		update_build_data "revert"
		usage ;; esac
done

# optional debug mode to view all output, uncomment to use and fill function with desired tests
# debug_mode

# separate the 'array' of branches into individual strings
BASE_BRANCH=$(echo "${BRANCH_SET}" | cut -d" " -f1)
PUB_BRANCH=$(echo "${BRANCH_SET}" | cut -d" " -f2)

# make sure the active local branches match the settings (and exit if they don't)
check_branches "${BASE_BRANCH}" "base"
check_branches "${PUB_BRANCH}" "public"

# check if branches are up to date with remote (and exit if they aren't)
check_remote_status "${BASE_BRANCH}" "base"
check_remote_status "${PUB_BRANCH}" "public"

# on 'fresh', delete public data before rebuild (ignores files by name from settings 'array')
if [ "${FRESH}" = "true" ]; then
	clear_pub_data
fi

# 'hugo build' plus any optional arguments
build_site

# add, commit, and push, baby!
deploy_to_remote
# endregion
