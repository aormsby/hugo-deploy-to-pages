#!/bin/sh

REGEX_IGNORE="\.|\.\.|\.git$|CNAME"

# append regex if user provided more specific input
if [ -n "${INPUT_DO_NOT_DELETE_REGEX}" ]; then
    REGEX_IGNORE="${REGEX_IGNORE}|${INPUT_DO_NOT_DELETE_REGEX}"
fi

# TODO: add to test mode to be able to see saved files using regex
clean_output_directory() {
    write_out "y" "'Full rebuild' option enabled. Deleting previous build output files." 1>&1

    # display ignored files for reference
    write_out "b" "Files matching these regex patterns will be saved:"
    for pattern in $(echo "${REGEX_IGNORE}" | sed "s/|/\\ /g"); do
        echo "${pattern}"
    done

    write_out "b" "Performing deletion step"

    # get filenames/directories to be deleted - ignored patterns are left out
    # shellcheck disable=SC2010
    DELETION_LIST=$(ls -a "${INPUT_HUGO_PUBLISH_DIRECTORY}" | grep -E -v "${REGEX_IGNORE}")

    # recursively delete remaining files and directories in the deletion list
    for item in ${DELETION_LIST}; do
        rm -r "${INPUT_HUGO_PUBLISH_DIRECTORY:?}/${item}"
        COMMAND_STATUS=$?

        if [ "${COMMAND_STATUS}" != 0 ]; then
            # exit on deletion failure
            write_out "y" "WARNING - '${item}' could not be deleted during full rebuild. Ignoring and continuing."
        fi
    done

    write_out -1 "'${INPUT_HUGO_PUBLISH_DIRECTORY}' cleaned out and ready for full rebuild."
    write_out "g" "SUCCESS\n"
}
