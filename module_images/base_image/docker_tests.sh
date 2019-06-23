#! /bin/bash
# If anything goes wrong, exit.
# if we use 'false' on it's own (without quotes), the program will stop.

set -eo pipefail
# echoes the command and it's arguments to STDERR
yell() { echo "$0: $*" >&2; }
# Calls yell and exits the program using code 111
die() {
    yell "$*"
    exit 111
}
# Tries the given command, if it fails, it will run the code on the right hand of the boolean "OR" (||) which calls the 'die' function with all the specified arguments
try() { "$@" || die "cannot $*"; }
# Special case for try to make the missing module more readable.
try_import() { "$@" || die "cannot find module ${@: -1}, full command: $*"; }

# Specify all the files you expect to exist here. Syntax is space separated double quoted values.
declare -a files_to_test=("main.py" "requirements.txt" "start_module.sh")
# Specify all the directories you expect to exist here. Syntax is space separated double quoted values.
declare -a directories_to_test=("module")
# reads the requirements.txt file of the module and puts each line in an array element
readarray libs <requirements.txt

for file in ${files_to_test[@]}; do
    # check if the file exists
    try [ -e $file ]
done

for dir in ${directories_to_test[@]}; do
    # check if the directory exists
    try [ -d $dir ]
done

for lib in ${libs[@]}; do
    # check if all libraries that are specified in requirements.txt are installed.
    try_import python -c "import sys, pkgutil; sys.exit(0 if pkgutil.find_loader(sys.argv[1]) else 1)" $lib
done
