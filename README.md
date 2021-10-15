## Zoneminder Docker
(Current version: 1.36)

We have set up a GoFundMe to fund the development of a new docker container that will be for Zoneminder and ES/ML with all the ES/ML modules pre-configured and for maintenance and support going forward.

[GoFundMe](https://www.gofundme.com/f/maintenance-of-zoneminder-docker-with-es-and-ml?utm_source=customer&utm_medium=copy_link&utm_campaign=p_cf+share-flow-1)

### About
This is an easy to run dockerized image of [ZoneMinder](https://github.com/ZoneMinder/zoneminder) along with the the [ZM Event Notification Server](https://github.com/pliablepixels/zmeventnotification) and its machine learning subsystem.

The configuration settings that are needed for this implementation of Zoneminder are pre-applied and do not need to be changed on the first run of Zoneminder.

This version will now upgrade Zoneminder from previous versions.

You can donate [here](https://www.paypal.com/us/cgi-bin/webscr?cmd=_s-xclick&amp;hosted_button_id=EJGPC7B5CS66E).

### Support
There is minimal support for this docker container at this time.

Go to the Zoneminder Forum [here](https://forums.zoneminder.com/) for support.

### Installation
Install the docker container by going to a command line and enter the command:

```bash
docker pull dlandon/zoneminder.machine.learning
```

This will pull the zoneminder docker image. Once it is installed you are ready to run the docker container.

Before you run the image, feel free to read the configuration section below to customize various settings.

To run Zoneminder:

```bash
docker run -d --name="Zoneminder" \
--net="bridge" \
--privileged="false" \
--shm-size="8G" \
-p 8443:443/tcp \
-p 9000:9000/tcp \
-e TZ="America/New_York" \
-e PUID="99" \
-e PGID="100" \
-e MULTI_PORT_START="0" \
-e MULTI_PORT_END="0" \
-v "/mnt/Zoneminder":"/config":rw \
-v "/mnt/Zoneminder/data":"/var/cache/zoneminder":rw \
dlandon/zoneminder.machine.learning
```

For http:// access use: `-p 8080:80/tcp`

### Shared Memory
Set shared memory to half of your installed memory.

### Subsequent runs

You can start/stop/restart the container anytime. You don't need to run the command above every time. If you have already created the container once (by the `docker run` command above), you can simply do a `docker stop Zoneminder` to stop it and a `docker start Zoneminder` to start it any time (or do a `docker restart Zoneminder`).

#### Customization

- Set `MULTI_PORT_START` and `MULTI_PORT_END` to define a port range for ES multi-port operation.
- The commands above use a host path of `/mnt/Zoneminder` to map the container config and cache directories. This is going to be persistent directory that will retain data across container/image stop/restart/deletes. ZM mysql/other config data/event files/etc are kept here. You can change this to any directory in your host path that you want to.

#### User Script

You can enable a custom user script that will run every time the container is started.

Put your script in the /mnt/Zoneminder/ folder and name it userscript.sh. The script will be executed each time the container is started before Zoneminder is started. Be sure to `chmod +x userscript.sh` so the script is executable. Set `ADVANCED_SCRIPT="1"` environment variable to enable your script.

#### Adding Nvidia GPU support to the Zoneminder.

You will have to install support for your graphics card. If you are using Unraid, install the Nvidia plugin and follow these [instructions](https://forums.unraid.net/topic/77813-plugin-linuxserverio-unraid-nvidia/?tab=comments#comment-719665). On other systems install the Nvidia docker, see [here](https://medium.com/@adityathiruvengadam/cuda-docker-%EF%B8%8F-for-deep-learning-cab7c2be67f9).

After you confirm the graphics card is seen by the Zoneminder docker container, you can then compile opencv with GPU support. Be sure your container can see the graphics card. Read the `opencv.sh` script for instructions on how to download the packages needed for compiling opencv. You will need to get a developer account for some of the packages because of licensing. Get into the docker command line by `docker exec -it Zoneminder /bin/bash` and do this once you have the packages:

```bash
cd /config/opencv
./opencv.sh
```

This will compile the opencv with GPU support. It takes a LONG time. You should then have GPU support.

You will have to install the CuDNN runtime yourself based on your particular setup.

#### Post install configuration and caveats

- After successful installation, please refer to the [ZoneMinder](https://zoneminder.readthedocs.io/en/stable/), [Event Server and Machine Learning](https://zmeventnotification.readthedocs.io/en/latest/index.html) configuration guides from the authors of these components to set it up to your needs. Specifically, if you are using the Event Server and the machine learning hooks, you will need to customize `/etc/zm/zmeventnotification.ini` and `/etc/zm/objectconfig.ini`.

- Note that by default, this docker build runs ZM on port 443 inside the docker container and maps it to port 8443 for the outside world. Therefore, if you are configuring `/etc/zm/objectconfig.ini` or `/etc/zm/zmeventnotification.ini` remember to use `https://localhost:443/<etc>` as the base URL.

- Push notifications with images will not work unless you replace the self-signed certificates that are auto-generated. Feel free to use the excellent and free [LetsEncrypt](https://letsencrypt.org) service if you'd like.

#### Usage

To access the Zoneminder GUI, browse to: `https://<your host ip>:8443/zm` or `http://<your host ip>:8080/zm` if `-p 8080:80/tcp` is specified.

The zmNinja Event Notification Server is accessed at port `9000`. Security with a self signed certificate is enabled. You may have to install the certificate on iOS devices for the event notification to work properly.

#### Troubleshooting when the container fails

If you have a situation where the container fails to start, you can set `NO_START_ZM="1"` as an environment variable - this will spin up the container but will not automatically start the MySql and Zoneminder processes. This way, you can get into a command line in the container (`docker exec -it Zoneminder /bin/bash`) and troubleshoot your issue by using the following commands to start MySql and Zoneminder and fix any errors/problems with them starting.

```bash
service mysql start
service zoneminder start
```

### Using Docker Compose (optional)

If you want to use Docker Compose to manage the Zoneminder Docker container, you can follow these steps.

Add the following to a docker-compose.yml file.

```
version: '3'
services:
  zoneminder:
    image: "dlandon/zoneminder.machine.learning"
    network_mode: bridge
    privileged: false
    shm_size: '4gb'
    ports:
      - "8443:443"
      - "9000:9000"
    environment:
      TZ: "Africa/Johannesburg"
      PUID: 99
      PGID: 100
      MULTI_PORT_START: 0
      MULTI_PORT_END: 0
    volumes:
      - /mnt/Zoneminder:/config
      - /mnt/Zoneminder/data:/var/cache/zoneminder
```
For http:// access add `- "8080:80"` under `ports`. 

In the directory where you saved the file, run the following to start the container:

```bash
docker-compose up -d
```

To stop the container:

```bash
docker-compose down
```

To get a command line interface inside the container, run:

```bash
docker-compose exec zoneminder bash
```
