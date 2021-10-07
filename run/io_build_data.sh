#!/bin/sh

DEPLOY_DATA_FILENAME="hugo-deploy.dat"

KEY_LAST_SOURCE_HASH="LAST_SOURCE_HASH"
KEY_LAST_BUILD_NUMBER="LAST_BUILD_NUMBER"
KEY_LAST_SOURCE_BUILD_TIME="LAST_SOURCE_BUILD_TIME"

# retrieve last build data
read_build_data() {
    if [ -f "${DEPLOY_DATA_FILENAME}" ]; then
        LAST_SOURCE_HASH=$(grep "${KEY_LAST_SOURCE_HASH}" "${DEPLOY_DATA_FILENAME}" | cut -d'=' -f2)
        LAST_BUILD_NUMBER=$(grep "${KEY_LAST_BUILD_NUMBER}" "${DEPLOY_DATA_FILENAME}" | cut -d'=' -f2)
        LAST_SOURCE_BUILD_TIME=$(grep "${KEY_LAST_SOURCE_BUILD_TIME}" "${DEPLOY_DATA_FILENAME}" | cut -d'=' -f2)

        # set default values for comparison to force a build if any value is missing
        if [ -z "${LAST_SOURCE_HASH}" ]; then
            write_out "y" "WARNING - '${DEPLOY_DATA_FILENAME}' does not contain last build hash. Resetting to 0 for this build."
            LAST_SOURCE_HASH=0
        fi

        if [ -z "${LAST_BUILD_NUMBER}" ]; then
            write_out "y" "WARNING - '${DEPLOY_DATA_FILENAME}' does not contain last build number. Resetting to 0 for this build."
            LAST_BUILD_NUMBER=0
        fi

        if [ -z "${LAST_SOURCE_BUILD_TIME}" ]; then
            write_out "y" "WARNING - '${DEPLOY_DATA_FILENAME}' does not contain last build time. Resetting to 0 for this build."
            LAST_SOURCE_BUILD_TIME=0
        fi
    else
        write_out "y" "WARNING - '${DEPLOY_DATA_FILENAME}' not found. New file will be created on successful build."
        LAST_SOURCE_HASH=0
        LAST_BUILD_NUMBER=0
        LAST_SOURCE_BUILD_TIME=0
    fi
}

# update stored build data after successful build
update_build_data() {
    LAST_SOURCE_HASH="${GITHUB_SHA}"
    LAST_BUILD_NUMBER=$((LAST_BUILD_NUMBER + 1))
    LAST_SOURCE_BUILD_TIME=$(git show --no-patch --no-notes --pretty='%cd' "${LAST_SOURCE_HASH}")
}

write_build_data() {
    # first entry is '>' to overwrite and start clean file, following are '>>' to append to file
    echo "${KEY_LAST_SOURCE_HASH}=${LAST_SOURCE_HASH}" >"${DEPLOY_DATA_FILENAME}"
    echo "${KEY_LAST_BUILD_NUMBER}=${LAST_BUILD_NUMBER}" >>"${DEPLOY_DATA_FILENAME}"
    echo "${KEY_LAST_SOURCE_BUILD_TIME}=${LAST_SOURCE_BUILD_TIME}" >>"${DEPLOY_DATA_FILENAME}"
    COMMAND_STATUS=$?

    if [ "${COMMAND_STATUS}" != 0 ]; then
        # exit on write build data fail
        write_out "${COMMAND_STATUS}" "Build data could not be written to '${DEPLOY_DATA_FILENAME}'. Try again, and please file a detailed issue on Github if the problem persists."
    fi

    write_out -1 "Build data written to '${DEPLOY_DATA_FILENAME}'"
    write_out "g" "SUCCESS\n"
}
