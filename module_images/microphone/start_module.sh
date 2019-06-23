#! /bin/sh
# Read the input arguments of the entrypoing.
COMMAND="$@" 

# If the "CLI" environment variable is set to true, we cun the command.
if [ -n "$CLI" ] && [ $CLI = true ]; then
    COMMAND="$@"
    exec $COMMAND
fi

# Run the main.py and redirect it's output to the module.log file.
python3 main.py 2>&1 | tee module.log &
while true; do
    sleep 1
done
