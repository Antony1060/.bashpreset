#source ./.bashcolors.sh

function line_up {
    echo -ne "\e[$1A"
}

function clear_line {
    echo -ne "\e[2K\r"
}

function is_user {
    [[ $EUID -eq $1 ]]
}

function ask_empty {
    RET=""
    read -p "$1 " RET
    printf "$RET"
}

function ask {
    RET=$(ask_empty "$1")
    while [[ -z $RET ]]; do
        RET=$(ask_empty "$1")
    done
    printf "$RET"
}

function ask_with_default {
    RET=$(ask_empty "$2[$1]:")
    if [[ -z $RET ]]; then
        RET=$1
    fi
    printf "$RET"
}

function prompt {
    RET=$(ask_empty "$1[Y/n]?" | tr '[:upper:]' '[:lower:]')
    while [[ -z $RET ]] || [[ $RET != "y" ]] && [[ $RET != "n" ]]; do
        RET=$(ask_empty "$1[Y/n]?" | tr '[:upper:]' '[:lower:]')
    done
    printf "$RET"
}

function prompt_autoyes {
    RET=$(ask_empty "$1[Y/n]?")
    while [[ -z $RET ]]; do
        RET="y"
    done
    printf "$(echo $RET | tr '[:upper:]' '[:lower:]')"
}

function log_info {
    printf "$AP_COLOR_LIGHT_GREEN →$AP_COLOR_RESET $1\n"
}

function count_command_runtime {
    tmpfile=$1
    arg=$2
    cmd_time=0
    last_time=$(date +%s%N)
    last_time=$(($last_time - 1000000000))
    while true; do
        curr_time=$(date +%s%N)
        if [[ $(($curr_time - $last_time)) -gt 1000000000 ]]; then
            if [[ $cmd_time -gt 0 ]]; then
                line_up 1
                clear_line
            fi
            if [[ -z $(cat $tmpfile) ]]; then
                printf "$AP_COLOR_YELLOW${cmd_time}s $AP_COLOR_DARK_GRAY|$AP_COLOR_RESET %s\n" "${*:2}"
                cmd_time=$(($cmd_time + 1))
                last_time=$(date +%s%N)
                continue
            fi

            exit_code=$(cat $tmpfile)
            if [[ $exit_code -ne 0 ]]; then
                printf "$AP_COLOR_RED${cmd_time}s($exit_code) $AP_COLOR_DARK_GRAY|$AP_COLOR_RESET %s\n" "${*:2}"
            else
                printf "$AP_COLOR_LIGHT_GREEN${cmd_time}s $AP_COLOR_DARK_GRAY|$AP_COLOR_RESET %s\n" "${*:2}"
            fi
            rm $tmpfile
            break;
        fi
    done
}

function run_command {
    local arg;
    for arg; do
        # while the tmpfile is empty, the command is running, once command is done, we fill the file with the exit code of the command
        # this file is used to track the command execution in the background process
        tmpfile=$(mktemp)
        count_command_runtime $tmpfile $arg &
        eval "${arg}" > /dev/null
        exit_code=$?
        echo "$exit_code" > $tmpfile
        # wait for background process to finish, i.e. the file is deleted
        while [ -f $tmpfile ]; do
            :
        done

        # exit if AP_EXIT_ON_FAIL is set and enabled and $exit_code is not 0
        if [[ $AP_EXIT_ON_FAIL -ne 0 ]] && [[ $exit_code -ne 0 ]]; then
            exit $exit_code
        fi
    done
}

function run_command_normal {
    local arg;
    for arg; do
        printf "$AP_COLOR_LIGHT_GREEN+$AP_COLOR_RESET %s\n" "$arg"
        eval "${arg}"

        # exit if AP_EXIT_ON_FAIL is set and enabled and $? is not 0
        if [[ $AP_EXIT_ON_FAIL -ne 0 ]] && [[ $? -ne 0 ]]; then
            exit $?
        fi
    done
}