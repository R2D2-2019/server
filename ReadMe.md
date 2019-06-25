These are the commands that were used to configure the server.
## System CTL changes:
	- `sudo systemctl enable docker` // Treats docker as a service, which means it'll get started up whenever the machine starts.

## Installing docker-compose
- Create directory for the binary<br>
	`sudo mkdir /opt`<br>
	`sudo mkdir /opt/bin`
- Download docker-compose binary<br>
	`sudo curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /opt/bin/docker-compose`
- Make binary executable<br>
	`sudo chmod +x /opt/bin/docker-compose`
- Now we can use docker-compose to run multi-container applications

## Network Topology
![BasicNetworkTopology](https://user-images.githubusercontent.com/31623036/59689742-7dc0cd00-91e0-11e9-8c2d-c5cb0c839fcd.png)

## Design Decisions
In this chapter we'll present the decisions we've made with regards to the server, network and accompanying infrastructure.

### Choice of OS
For the R2-D2 server we chose CoreOS (also known as `Container Linux`).
The rationale was that we wanted an OS that was as lightweight as possible. This is so that we can dedicate as many of the resources as possible to the containers.
Linux itself was already winning on this front versus a windows server purely based on resource usage.
CoreOS was selected based on the fact that it's a distribution made to manage containers. It contains only the bare minimum of tools/packages necessary for running linux, network management, raid management and container management. By using this distribution we're able to dedicate almost all system resources to the containers.

### Choice of container software
We've decided to use Docker for our containers. 
We chose to use Docker based on the fact that it's one of, if not the, most widely-used containerization software on the market right now. This means that there is extensive documentation, troubleshooting and more available on the internet should we encounter any issues. 
Alternatives such as Kubernetes were appealing as well, but we decided to go with the software that had the biggest community.



## Testing the images and containers
<details><summary>Click here to show the testing information</summary>
Once you've cloned the repository, you can navigate to the `module_images` folder. 
In there you'll find one folder for each of the modules that have to run on the server.
Each folder contains the following files:
 - `Dockerfile`
 - `requirements.txt`
 - `start_module.sh`
 - `docker_tests.sh`

Each file serves a purpose in the building of an image, which is what 'runs' inside a Docker container.

### Dockerfile
The `Dockerfile` contains the instructions for Docker. 
It pulls the base image from the Docker repository, we're using Python Alpine, which is an image of the Alpine Linux distro.
Once we have the image, we install the packages we need. The packages that every image needs in our case are: `git` and `bash`.
The `git` package is used to clone the repositories and the `bash` package is used to run our tests.

After having installed the required packages, docker will setup some variables, such as the repository of the module and the branch it needs to pull. The default branch is `release`.

Once the repositories (`r2d2-python-build` and the module repository) have been cloned, we copy our scripts and the requirements file to the module's working directory. We then install the libraries listed in the `requirements.txt` file, if it's empty it won't install anything.

Finally we give the execute permission to our test and run scripts and set the `ENTRYPOINT` of our container image. 
The `ENTRYPOINT` is the script that will be called when the container starts.

### Requirements.txt
The `requirements.txt` file is a simple textfile in which each module's pip requirements are listed.
Currently we don't support version numbers as the literal value is used by the testing scripts to check that the libraries are available.

### Start_module.sh
The `start_module.sh` is our entrypoint for the containers. 
At first it will check for a command it has to run instead of it's default application.
If there wasn't any command specified, it will start the module's `main.py` in the background and start an endless loop of `sleep 1`. The reason for the `sleep` and the endless while loop is that if a module crashes, or 'finishes' running, the container will shut down, making it incredibly hard to debug.
Thanks to the loop, we're able to keep the container running to inspect it using a console.

### Docker_tests.sh
The `docker_tests.sh` file specifies the tests it has to run for that specific container.
It will specify an array of files it expects to exist, an array of directories it expects to exist and an array of python libraries that need to be installed.
The script will loop over each of the three arrays and check whether or not the files/directories we expect are listed, and it'll loop over the list of libraries defined in `requirements.txt` and attempt to import them into the python interpreter. 
Should any of the checks fail, the script will terminate with return code `111`.

### Dockerfile_tests.sh
The `dockerfile_tests.sh` file can be found in `modules_images/`, it defines a testing procedure for the containers.

It has two modes:
 1. Test all
 2. Test specific

The first mode (`test all mode`) runs the entire testing process for each of the images stored in the directories that are specified in the `images_to_test` array.
The second mode (`test specific mode`) will only run the testing process for the target image. 

For both of the modes, the golden rule is that if any operation fails, the entire testing process will terminate.
To avoid your terminal from getting too full, we've piped the output of the `docker build` command to the `build.log` file. 
This file is cleared each and every time you run the script. It will overwrite the file with each new build attempt such that you only get to see the output of either the last successful build or the failing build.

To run the script, you first need to make the script executable (1-time step only):
`chmod +x ./dockerfile_tests.sh` running this command from the `module_images/` folder will make the script executable.

To run the first mode, all you need to do is run the following command and wait:
`./dockerfile_tests.sh`

You can cancel the script at any time by pressing `CTRL+C` 

To run the test suite on only one image, you can call the script like so:

`TARGET="the_target_image" ./dockerfile_tests.sh`

You can only specify one target at a time.
The target name must be identical to the folder name of the image you want to test.

</details>