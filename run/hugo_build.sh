#!/bin/sh

# run 'hugo build' plus any input_hugo_build_options
build_site() {
    write_out -1 "Running 'hugo' build command with provided build options -- '${INPUT_HUGO_BUILD_OPTIONS}'"
    write_out "b" "\nHugo build output:"

    # shellcheck disable=SC2086
    HUGO_BUILD_OUTPUT=$(hugo ${INPUT_HUGO_BUILD_OPTIONS})
    COMMAND_STATUS=$?

    if [ "${COMMAND_STATUS}" != 0 ]; then
        # exit on hugo build errors
        write_out "${COMMAND_STATUS}" "Hugo build failed with errors. Check output for details."
    fi

    HUGO_WARNINGS=$(echo "${HUGO_BUILD_OUTPUT}" | grep "WARN")

    write_out -1 "${HUGO_BUILD_OUTPUT}"

    if [ "${INPUT_STRICT_MODE}" = true ] &&
        [ -n "${HUGO_WARNINGS}" ]; then
        write_out "255" "Hugo build failed with warnings in 'strict mode'. Check output for details."
    fi

    write_out -1 "Hugo build step complete"
    write_out "g" "SUCCESS\n"
}
