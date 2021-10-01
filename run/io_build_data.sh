#!/bin/sh

DEPLOY_DATA_FILENAME="hugo-deploy.dat"

KEY_LAST_HASH="LAST_HASH"
KEY_LAST_BUILD_NUMBER="LAST_BUILD_NUMBER"

# retrieve last build data
read_build_data() {
    if [ -f "${DEPLOY_DATA_FILENAME}" ]; then
        LAST_HASH=$(grep "${KEY_LAST_HASH}=" "${DEPLOY_DATA_FILENAME}" | cut -d'=' -f2)
        LAST_BUILD_NUMBER=$(grep "${KEY_LAST_BUILD_NUMBER}=" "${DEPLOY_DATA_FILENAME}" | cut -d'=' -f2)

        # set default values for comparison to force a build if any value is missing
        if [ -z "${LAST_HASH}" ]; then
            LAST_HASH=0
            write_out "y" "WARNING - '${DEPLOY_DATA_FILENAME}' does not contain last build hash. Resetting to 0 for this build."
        fi

        if [ -z "${LAST_BUILD_NUMBER}" ]; then
            LAST_BUILD_NUMBER=0
            write_out "y" "WARNING - '${DEPLOY_DATA_FILENAME}' does not contain last build number. Resetting to 0 for this build."
        fi
    else
        # shellcheck disable=SC2034
        LAST_HASH=0
        # shellcheck disable=SC2034
        LAST_BUILD_NUMBER=0

        write_out "y" "WARNING - '${DEPLOY_DATA_FILENAME}' not found. New file will be created on successful build."
    fi
}

# update stored build data after successful build
update_build_data() {
    LAST_HASH="${GITHUB_SHA}"
    LAST_BUILD_NUMBER=$((LAST_BUILD_NUMBER + 1))
}

write_build_data() {
    # first entry is '>' to overwrite and start clean file, following are '>>' to append to file
    echo "${KEY_LAST_HASH}=${LAST_HASH}" >"${DEPLOY_DATA_FILENAME}"
    echo "${KEY_LAST_BUILD_NUMBER}=${LAST_BUILD_NUMBER}" >>"${DEPLOY_DATA_FILENAME}"
    COMMAND_STATUS=$?

    if [ "${COMMAND_STATUS}" != 0 ]; then
        # exit on write build data fail
        write_out "${COMMAND_STATUS}" "Build data could not be written to '${DEPLOY_DATA_FILENAME}'. Try again, and please file a detailed issue on Github if the problem persists."
    fi

    write_out -1 "Build data written to '${DEPLOY_DATA_FILENAME}'"
    write_out "g" "SUCCESS\n"
}
