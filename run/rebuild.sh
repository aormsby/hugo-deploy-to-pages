#!/bin/sh

REGEX_IGNORE="^\.+$|^\.git$|^CNAME$"

# append regex if user provided more specific input
if [ -n "${INPUT_DO_NOT_DELETE_REGEX}" ]; then
    REGEX_IGNORE="${REGEX_IGNORE}|${INPUT_DO_NOT_DELETE_REGEX}"
fi

clean_output_directory() {
    write_out "y" "'Full rebuild' option enabled. Deleting previous build files." 1>&1

    # print ignore pattern for reference
    write_out "b" "Items matching these regex patterns will be saved:"
    for pattern in $(echo "${REGEX_IGNORE}" | sed "s/|/\\ /g"); do
        echo "${pattern}"
    done

    # get items to be saved/deleted
    DIR_CONTENTS=$(ls -a "${INPUT_HUGO_PUBLISH_DIRECTORY}")
    DELETION_LIST=$(echo "${DIR_CONTENTS}" | grep -E -v "${REGEX_IGNORE}")

    # print save/deletion lists for verbose output
    if [ "${INPUT_FULL_REBUILD_VERBOSE}" = true ]; then
        SAVE_LIST=$(echo "${DIR_CONTENTS}" | grep -E "${REGEX_IGNORE}")

        write_out "b" "Items being saved:"
        write_out -1 "${SAVE_LIST}"
        write_out "b" "Items being deleted:"
        write_out -1 "${DELETION_LIST}"
    fi

    write_out "b" "Performing deletion step"

    # recursively delete remaining items in the deletion list
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
