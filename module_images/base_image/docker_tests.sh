#! /bin/bash
declare -a test_commands
test_commands[main_exists]="ls main.py"
image_name="$NAME"
for command_key in ${!test_commands[@]}; do
    if ! ${test_commands[command_key]}; then
        false
    fi
done