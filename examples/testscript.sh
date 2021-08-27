#!/bin/bash

source ".bashpreset.sh"

AP_EXIT_ON_FAIL=0

# this command will fail, and if AP_EXIT_ON_FAIL is set to 1, program will exit after
run_command "sleep 2 && echo hi && false"
run_command "echo hi && sleep 4"