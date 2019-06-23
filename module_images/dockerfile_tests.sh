#!/bin/bash
# If anything returns an error, just stop the tests.
set -eo pipefail

# If debug is set, we output all the commands and variables being run
[ "$DEBUG" ] && set -x

# CD to the directory of the script, so that we know where the image folders are.
cd "$(dirname "$0")"
> build.log
yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 111; }
try() { "$@" || die "cannot $*"; }

declare -a images_to_test=("base_image" "main_server" "microphone" "swarm_analytics" "swarm_management" "swarm_ui" "CAN_Navigation" "voice_interaction")
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
    name=${x,,}
    printf $'%-30s %-30s\n' "$name" "Building image"    # docker tags have to be lower_case
    docker build -t "$name" ./"$x" &>build.log &        # redirect STDOUT to /dev/null to only show errors. Also run in background
    pid=$!                                              # Process Id of the previous running command
    spin='-\|/'                                         # spinner characters
    i=0                                                 # increment the character we want to show
    while kill -0 $pid 2>/dev/null; do                  # wait for the docker build to be complete
        i=$(((i + 1) % 4))                              # get the animation character
        printf "\r${spin:$i:1}"                         # erase the previous animation character and print the next one.
        sleep .1                                        # delay a slight bit.
    done
    if ! docker inspect "$name" &>/dev/null; then
        printf $'\r Something went wrong while building the image! check the logs!\n'
        false
    else
        printf $'\r%-30s image built.\n' "$x"               # print that the current image is built so that it doesn't feel so long
    fi
    if ! docker run -ti -e="CLI=true" $name ./docker_tests.sh; then
        false
    fi
    echo "test"
    break
done

