#! /bin/sh

# Run the main.py and redirect it's output to the module.log file.
python3 manager/manager.py 2>&1 | tee module.log &
while true
do
	sleep 1
done