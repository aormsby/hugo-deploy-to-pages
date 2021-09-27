#!/bin/sh

KEY_LAST_HASH="LAST_HASH"
KEY_LAST_BUILD_NUMBER="LAST_BUILD_NUMBER"

# retrieve last build data from hugo-deploy.dat
read_build_data() {
    if [ -f "hugo-deploy.dat" ]; then
        LAST_HASH=$(grep "${KEY_LAST_HASH}=" dattest.dat | cut -d'=' -f2)
        LAST_BUILD_NUMBER=$(grep "${KEY_LAST_BUILD_NUMBER}=" dattest.dat | cut -d'=' -f2)

        # set default values for comparison to force a build if any value is missing
        if [ -z "${LAST_HASH}" ] ||
            [ -z "${LAST_BUILD_NUMBER}" ]; then
            LAST_HASH=0
            LAST_BUILD_NUMBER=0
            write_out "y" "WARNING - 'hugo-deploy.dat' build data found. Resetting build data and forcing a build to create the missing data."
        fi
    else
        # shellcheck disable=SC2034
        LAST_HASH=0
        # shellcheck disable=SC2034
        LAST_BUILD_NUMBER=0
    fi
}

# update stored build data after successful build
update_build_data() {
    LAST_HASH="${CURRENT_SOURCE_HEAD}"
    LAST_BUILD_NUMBER=$((LAST_BUILD_NUMBER + 1))
}

write_build_data() {
    # clear file data
    echo >hugo-deploy.dat

    echo "${KEY_LAST_HASH}=${LAST_HASH}
    ${KEY_LAST_BUILD_NUMBER}=${LAST_BUILD_NUMBER}" >>hugo-deploy.dat
    COMMAND_STATUS=$?

    if [ "${COMMAND_STATUS}" != 0 ]; then
        # exit on write build data fail
        write_out "${COMMAND_STATUS}" "Build data could not be written for some reason. Try again, and please file a detailed issue on Github if the problem persists."
    fi

    write_out -1 "Build data written to 'hugo-deploy.dat'"
    write_out "g" "SUCCESS\n"
}
