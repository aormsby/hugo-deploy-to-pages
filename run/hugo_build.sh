#!/bin/sh

# run 'hugo build' plus any input_hugo_build_options
build_site() {
    write_out -1 "Running 'hugo' build command with provided build options -- '${INPUT_HUGO_BUILD_OPTIONS}'"
    
    # shellcheck disable=SC2086
	hugo ${INPUT_HUGO_BUILD_OPTIONS}
    COMMAND_STATUS=$?
    
    if [ "${COMMAND_STATUS}" != 0 ]; then
        # exit on hugo build fail
        write_out "${COMMAND_STATUS}" "Hugo build failed. Check output for details."
    fi
}
