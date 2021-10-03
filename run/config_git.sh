#!/bin/sh

# called by run_action.sh
config_for_action() {
    write_out -1 "Setting git config from input vars. (Skips config for all inputs set to 'null'.)"
    get_current_user_config
    set_git_config "."

    if [ "${PUBLISH_TO_SUBMODULE}" = true ]; then
        set_git_config "${INPUT_HUGO_PUBLISH_DIRECTORY}"
    fi

    write_out "g" "SUCCESS\n"
}

# store current user config data for reset after action run
get_current_user_config() {
    CURRENT_USER=$(git config --get --default="null" user.name)
    CURRENT_EMAIL=$(git config --get --default="null" user.email)
    CURRENT_PULL_CONFIG=$(git config --get --default="false" pull.rebase)
}

# set action config values
set_git_config() {
    # only set user if config is empty
    if [ "${CURRENT_USER}" = "null" ] &&
        [ "${INPUT_GIT_CONFIG_USER}" != "null" ]; then
        git -C "${1}" config user.name "${INPUT_GIT_CONFIG_USER}"
    fi

    # only set email if config is empty
    if [ "${CURRENT_EMAIL}" = "null" ] &&
        [ "${INPUT_GIT_CONFIG_EMAIL}" != "null" ]; then
        git -C "${1}" config user.email "${INPUT_GIT_CONFIG_EMAIL}"
    fi

    # always set pull.rebase with worflow value (default false)
    git -C "${1}" config pull.rebase "${INPUT_GIT_CONFIG_PULL_REBASE}"
}

reset_config_after_action() {
    write_out -1 "Resetting git config to previous settings."
    reset_git_config "."

    if [ "${PUBLISH_TO_SUBMODULE}" = true ]; then
        reset_git_config "${INPUT_HUGO_PUBLISH_DIRECTORY}"
    fi
    
    write_out "b" "Reset Complete\n"
}

# reset to original user config values
reset_git_config() {
    if [ "${CURRENT_USER}" = "null" ]; then
        git -C "${1}" config --unset user.name
    else
        git -C "${1}" config user.name "${CURRENT_USER}"
    fi

    if [ "${CURRENT_EMAIL}" = "null" ]; then
        git -C "${1}" config --unset user.email
    else
        git -C "${1}" config user.email "${CURRENT_EMAIL}"
    fi

    git -C "${1}" config pull.rebase "${CURRENT_PULL_CONFIG}"
}
