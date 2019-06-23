#! /bin/sh
COMMAND="$@"

if [ -n "$CLI" ] && [ $CLI = true ]; then
    COMMAND="$@"
fi

exec $COMMAND
# Run the main.py and redirect it's output to the module.log file.
python3 main.py 2>&1 | tee module.log &
while true
do
	sleep 1
done