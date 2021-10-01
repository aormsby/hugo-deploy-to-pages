#!/bin/sh

REGEX_IGNORE="CNAME"

# append regex if user provided more specific input
if [ -n "${INPUT_DO_NOT_DELETE_REGEX}" ]; then
    REGEX_IGNORE="${REGEX_IGNORE}|${INPUT_DO_NOT_DELETE_REGEX}"
fi

print_regex_patterns() {
    write_out "y" "'Full rebuild' option enabled." 1>&1

    # display ignored files for reference
    write_out "b" "Input regex patterns:"
    for pattern in $(echo "${REGEX_IGNORE}" | sed "s/|/\\ /g"); do
        echo "${pattern}"
    done

    PUBLISH_DIR_CONTENTS=$(ls -a "${INPUT_HUGO_PUBLISH_DIRECTORY}")
}

print_files_to_save() {
    write_out "b" "Files to SAVE:" 1>&1
    for item in $(echo "${PUBLISH_DIR_CONTENTS}" | grep -E "${REGEX_IGNORE}"); do
        echo "${item}"
    done
}

print_files_to_delete() {
    write_out "b" "Files to DELETE:" 1>&1
    for item in $(echo "${PUBLISH_DIR_CONTENTS}" | grep -E -v "${REGEX_IGNORE}"); do
        echo "${item}"
    done
}
