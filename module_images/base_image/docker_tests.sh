#! /bin/bash
set -eo pipefail
yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 111; }
try() { "$@" || die "cannot $*"; }
try_import() { "$@" || die "cannot find module ${@: -1}, full command: $*"; }

declare -a files_to_test=("main.py" "requirements.txt" "start_module.sh")
declare -a directories_to_test=("module")
readarray libs < requirements.txt

for file in ${files_to_test[@]}; do
    try [ -e $file ]                    # check if the file exists
done

for dir in ${directories_to_test[@]}; do
    try [ -d $dir ]                     # check if the directory exists
done

for lib in ${libs[@]}; do
    try_import python -c "import sys, pkgutil; sys.exit(0 if pkgutil.find_loader(sys.argv[1]) else 1)" $lib
done