source ./.bashcolors.sh

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
                printf "$AP_COLOR_GREEN${cmd_time}s $AP_COLOR_DARK_GRAY|$AP_COLOR_RESET %s\n" "${*:2}"
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