#!/bin/bash
# If anything returns an error, just stop the tests.
# if we use 'false' on it's own (without quotes), the program will stop.
set -eo pipefail

# If debug is set, we output all the commands and variables being run
[ "$DEBUG" ] && set -x

# CD to the directory of the script, so that we know where the image folders are.
cd "$(dirname "$0")"
#clears the build.log file
>build.log
# echoes the command and it's arguments to STDERR
yell() { echo "$0: $*" >&2; }
# Calls yell and exits the program using code 111
die() {
    yell "$*"
    exit 111
}
# Tries the given command, if it fails, it will run the code on the right hand of the boolean "OR" (||) which calls the 'die' function with all the specified arguments
try() { "$@" || die "cannot $*"; }

# array of image names. These should be the image directories.
# Space separated double quoted values.
if [[ -n $TARGET ]]; then
    declare -a images_to_test=($TARGET)
else
    declare -a images_to_test=("base_image" "main_server" "microphone" "swarm_analytics" "swarm_management" "swarm_ui" "CAN_Navigation" "voice_interaction")
fi

for i in ${images_to_test[@]}; do
    # Docker tags should be lower_case
    name=${i,,}
    # redirect STDOUT to /dev/null to only show errors.
    if ! docker inspect "$name" &>/dev/null; then
        printf '%-30s image does not exist\n' "$i"
    else
        printf '%-30s image exists, cleaning it.\n' "$i"
        # remove the image if it exists so that we can actually test a clean build.
        docker image rm -f "$name"
    fi
done

for x in ${images_to_test[@]}; do
    # docker tags have to be lower_case
    name=${x,,}
    printf $'%-30s %-30s\n' "$name" "Building image"
    # redirect STDOUT to /dev/null to only show errors. Also run in background
    docker build -t "$name" ./"$x" &>build.log &
    # Process Id of the previous running command
    pid=$!
    # spinner characters
    spin='-\|/'
    # increment the character we want to show
    i=0
    # wait for the docker build to be complete
    while kill -0 $pid 2>/dev/null; do
        # get the animation character
        i=$(((i + 1) % 4))
        # erase the previous animation character and print the next one.
        printf "\r${spin:$i:1}"
        # delay a slight bit.
        sleep .1
    done
    # for some reason, if the image build fails it doesn't actually stop the script, so we check that the image exists in docker.
    # The image should only exist if the build was successful.
    if ! docker inspect "$name" &>/dev/null; then
        printf $'\r Something went wrong while building the image! check the logs!\n'
        false
    else
        printf $'\r%-30s image built.\n' "$x" # print that the current image is built so that it doesn't feel so long
    fi
    # runs the image-specific test script.
    if ! docker run -ti -e="CLI=true" $name ./docker_tests.sh; then
        false
    fi
done
