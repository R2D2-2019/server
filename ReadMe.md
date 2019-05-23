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
