#!/bin/sh

DEPLOY_DATA_FILENAME="hugo-deploy.dat"

KEY_LAST_HASH="LAST_HASH"
KEY_LAST_BUILD_NUMBER="LAST_BUILD_NUMBER"

# retrieve last build data from hugo-deploy.dat
read_build_data() {
    if [ -f "${DEPLOY_DATA_FILENAME}" ]; then
        LAST_HASH=$(grep "${KEY_LAST_HASH}=" dattest.dat | cut -d'=' -f2)
        LAST_BUILD_NUMBER=$(grep "${KEY_LAST_BUILD_NUMBER}=" dattest.dat | cut -d'=' -f2)

        # set default values for comparison to force a build if any value is missing
        if [ -z "${LAST_HASH}" ] ||
            [ -z "${LAST_BUILD_NUMBER}" ]; then
            LAST_HASH=0
            LAST_BUILD_NUMBER=0
            write_out "y" "WARNING - '${DEPLOY_DATA_FILENAME}' build data found. Resetting build data and forcing a build to create the missing data."
        fi
    else
        touch "${DEPLOY_DATA_FILENAME}"
        # shellcheck disable=SC2034
        LAST_HASH=0
        # shellcheck disable=SC2034
        LAST_BUILD_NUMBER=0
    fi
}

# update stored build data after successful build
update_build_data() {
    # LAST_HASH="${CURRENT_SOURCE_HEAD}"
    LAST_HASH="${GITHUB_SHA}"
    LAST_BUILD_NUMBER=$((LAST_BUILD_NUMBER + 1))
}

write_build_data() {
    # # clear file data
    # echo >"${DEPLOY_DATA_FILENAME}"

    echo "${KEY_LAST_HASH}=${LAST_HASH}
    ${KEY_LAST_BUILD_NUMBER}=${LAST_BUILD_NUMBER}" >"${DEPLOY_DATA_FILENAME}"
    COMMAND_STATUS=$?

    if [ "${COMMAND_STATUS}" != 0 ]; then
        # exit on write build data fail
        write_out "${COMMAND_STATUS}" "Build data could not be written for some reason. Try again, and please file a detailed issue on Github if the problem persists."
    fi

    write_out -1 "Build data written to '${DEPLOY_DATA_FILENAME}'"
    write_out "g" "SUCCESS\n"
}
