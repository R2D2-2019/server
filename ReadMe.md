
## Setting up the server

### 1. Downloading CoreOS and setting up SSH keys
**Requirements:** 2 USB-sticks
#### Creating bootable USB
1. The coreOS (Container Linux) ISO can be found here: [direct link](https://stable.release.core-os.net/amd64-usr/current/coreos_production_iso_image.iso) (Stable channel)
2. Create a bootable usb using your favorite tool (like [Etcher](https://www.balena.io/etcher/))

#### Creating an ignition config
You cannot login to the server using a username/password combination, instead it uses your PC's public key.
**EDIT:** You can actually use a password username/password combination too, explanation can be found [here](https://github.com/coreos/container-linux-config-transpiler/blob/master/doc/examples.md)

Our basic ignition file looks like this:
```json
{
  "ignition": {
    "config": {},
    "timeouts": {},
    "version": "2.1.0"
  },
  "networkd": {},
  "passwd": {
    "users": [
      {
        "name": "core",
        "sshAuthorizedKeys": [
          "PLACE YOUR KEY HERE"
        ]
      }
    ]
  },
  "storage": {},
  "systemd": {}
}
```
Replace `PLACE YOUR KEY HERE` with your own public key, you can add multiple keys in the following manner:
```json
"sshAuthorizedKeys": [
   "PLACE YOUR KEY HERE",
   "ANOTHER KEY HERE"
]
```
**Optional:** You can also change the default core username to something else or add extra users.
When you are done editing the config you can validate it using the [online validator](https://coreos.com/validate/).

Save to json file to something like `ignition.json` and save it to the other USB-drive.

### 2. Installing CoreOS and the ignition file
1. Place both USB-drives into the server and boot from the CoreOS drive.
2. After booting up you will be greeted with a prompt
3. To install CoreOS to the disk execute the following command:
`coreos-install -d /dev/your_drive -i ignition.json`
replace `your_drive` with the correct drive identifier (someting like `sda`)
locate the other usb drive and point towards the ignition file, you will probably need to mount the USB drive first
4. After it is finished, reboot the machine and unplug the drives.
5. Congratulations you have succesfully installed CoreOS on the server, you can now use SSH to login to the server using `core@ipaddress` (if you kept the username as core).

**Note:** the server uses it's ip-address as it's hostname.

### 3. Server configuration
**3.1. System CTL changes:**

`sudo systemctl enable docker` // Treats docker as a service, which means it'll get started up whenever the machine starts.

**3.2. Installing docker-compose:**
- Create directory for the binary
	`sudo mkdir /opt`
	`sudo mkdir /opt/bin`
- Download docker-compose binary
	`sudo curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /opt/bin/docker-compose`
- Make binary executable
	`sudo chmod +x /opt/bin/docker-compose`
- Now we can use docker-compose to run multi-container applications

**3.3. Setting up software-RAID**
The server doesn't contain a Hardware-RAID controller, so we are going to setup software RAID, the server contains 4 Drives, 2x 500GB and 2x1TB.
You can't setup sofware RAID on the boot drive, so we installed CoreOS on one of the 500GB drives.
We are going to use the two 1TB drives in RAID-1 configuration.

1. Find the correct drive identifications using `fdisk -l` this will show all drives, it's disk size and drive label.
2. After you have found the disks, you need to erase the contents/partitions of it, for example if your drive is `sda` use `fdisk /dev/sda` to select the drive. Press `p` to show the partitions on the drive. Press `d` to delete a partition, select the partition number and press enter again. Do this until all partitions are erased. When you are done press `w` to write (save) the changes.
Do this for all the drives you are going to use for the RAID partition. **Make sure not to accidentally erase the boot drive as you'll have to start all over.**
3. In order to create the RAID disk use:<br>
`sudo mdadm --create --verbose /dev/md0 --level=1 --raid-devices=2 /dev/sda /dev/sdb`
**Explanation:**
`/dev/md0` The RAID disks name.
`--level=1` The RAID level eq RAID-1.
`--raid-devices=2` The amount of disks this RAID setup will contain.
`/dev/sda /dev/sdb` The devices that will be included in the RAID array, there should be as many disk paths as has been specified by `--raid-devices=`
     - You might get a warning that looks something like this: `this array has metadata at the start and may not be suitable as a boot device.` You can just press `y` to build the RAID anyway.
4. mdadm will start to mirror the drives, to check the status of this you can use `cat /proc/mdstat`
**Note:** You don't have to wait for this process to finish. If you shutdown the server correctly (By running `shutdown -P now` for example), the creation of the raid should resume on next boot. This is not the case for a blackout. If the server doesn't shutdown properly, you'll have to do all the steps from section 3.3 again.

**3.4 Create and mount the filesystem**
In order to use the newly created RAID drive we need to create a new filesystem for that drive.
1. To create a ext4 partition on the drive use `sudo mkfs.ext4 -F /dev/md0`.
    - Replace `/dev/md0` with the drive letter you chose in step 3.3.3
2. Create a mount point for the drive `sudo mkdir -p /mnt/raid`. (you can replace `raid` with the desired drive name.)
3. Mount the drive using `sudo mount /dev/md0 /mnt/raid`.
   - Replace `/dev/md0` with the drive letter you chose in step 3.3.3
   - Replace `/mnt/raid` with the drive letter you chose in step 3.4.2
4. The RAID drive is now accessible at the drive path you chose in step 3.4.2 (`/mnt/raid` in our example)

**3.5 Make Docker use the new RAID setup**
1. Stop the Docker service `sudo systemctl stop docker` 
2. Create a directory for the "drop-in file" `sudo mkdir /etc/systemd/system/docker.service.d`
3. Create the Docker config file `sudo touch /etc/systemd/system/docker.service.d/docker.conf`
4. Open the newly created `docker.conf` file and add the following:

```
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd --graph="/mnt/raid" --storage-driver=devicemapper
```

**Note:** replace `/mnt/raid` with the name chosen in step 3.4.2

5. Reload the Docker deamon `sudo systemctl daemon-reload`
6. Start the Docker service `sudo systemctl start docker`
7. Congratulations the Docker images/containers will now use the RAID setup.

**3.6 setting up the docker management software**

To manage our containers, we've decided to user [Portainer](https://www.portainer.io/).
It provides an easy to use graphical interface for managing containers, images and more. 
You can find the Portainer documentation here: [docs](https://portainer.readthedocs.io/en/stable/)

The setup is very simple, just run the following commands:
1. `docker volume create portainer_data` - This command creates persistent storage for containers. Normally containers keep their data in RAM (using a RAM File System) but using a volume means that the data is still available even after the container is restarted.
2. `docker run -d -p 9000:9000 --name portainer --restart always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer`
  - `docker run` starts a container
  - `-d` means that the container will run as a `daemon` (a service in the background)
  - `-p 9000:9000` means that port `9000` on the container is exposed to port `9000` on the server (which makes it accessible within the network)
  - `--name portainer` sets the name of the container to `portainer`
  - `--restart always` makes it so that if, for whatever reason, the container shuts-down it will start back up. 
  - `-v /var/run/docker.sock:var/run/docker.sock` This command binds a volume to the container, namely `docker.sock`. 
    - The there are two parameters, separated by the `:` symbol.
    - The first parameter is the name of the volume on the server
    - The second parameter is where this volume will be available within the container (in this case `var/run/docker.sock`)
  - `-v portainer_data:/data portainer/portainer` This parameter does the same as the previous parameter except it binds the volume we created earlier to the container.
    - This is where portainer will store it's data.
  - `portainer/portainer` is the image name. It tells docker to:
    1. Look into the `portainer` repository
    2. Fetch the image called `portainer` from there

Portainer will now be availble from the R2D2 network by going to: `server_ip:9000` where `server_ip` is the IP that the router assigned to the server.

## Network Topology
![BasicNetworkTopology](https://user-images.githubusercontent.com/31623036/59689742-7dc0cd00-91e0-11e9-8c2d-c5cb0c839fcd.png)

**4. Setting up the Router**
The setup process for the router is quite simple.
1. Plug an ethernet cable into the *blue* port of the router.
2. Plug the other end of that cable into a working (patched) ethernet port in the lab.
3. Plug an ethernet cable into the built-in ethernet adapter of the server (this means the port that is **not** one of the PCI(-E) extension cards)
4. Plug the other end into one of the *yellow* ports of the router

Now that the server is connected to the R2D2 network, it should also have internet access through EduRoam.

To access the server, you'll need to be connected to the same router.
The easiest way to do so is to connect using an ethernet cable.

To manage the router, you can open your browser and either go to: `10.0.1.1` or to `http://tplinklogin.net/`. 
The page will ask for a username and password, they are both `admin`. (It is strongly advised to change these credentials, but we have reset them for next year)
If nothing has changed on the server/network, the server's IP address should be `10.0.1.60`.

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
