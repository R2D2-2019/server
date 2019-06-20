#!/bin/bash
# If anything returns an error, just stop the tests.
set -eo pipefail

# If debug is set, we output all the commands and variables being run
[ "$DEBUG" ] && set -x

# CD to the directory of the script, so that we know where the image folders are.
cd "$(dirname "$0")"

declare -a images_to_test=("main_server" "microphone" "swarm_analytics" "swarm_management" "swarm_ui" "CAN_Navigation" "voice_interaction")
declare images_exist=true
for i in ${images_to_test[@]}; do
    name=${i,,}                                     # Docker tags should be lower_case
    if ! docker inspect "$name" &>/dev/null; then   # redirect STDOUT to /dev/null to only show errors.
        printf '%-30s image does not exist\n' "$i"
        images_exist=false
    else
        printf '%-30s image exists, cleaning it.\n' "$i"
        docker image rm -f "$name"
    fi
done

for x in ${images_to_test[@]}; do
    name=${x,,}                                     # docker tags have to be lower_case
    docker build -t "$name" ./"$x" &>/dev/null &    # redirect STDOUT to /dev/null to only show errors. Also run in background
    pid=$!                                          # Process Id of the previous running command
    spin='-\|/'                                     # spinner characters
    i=0                                             # increment the character we want to show
    while kill -0 $pid 2>/dev/null; do              # wait for the docker build to be complete
        i=$(((i + 1) % 4))                          # get the animation character
        printf "\r${spin:$i:1}"                     # erase the previous animation character and print the next one.
        sleep .1                                    # delay a slight bit.
    done
    printf $'\r%-30s image built.\n' "$x"           # print that the current image is built so that it doesn't feel so long
done
