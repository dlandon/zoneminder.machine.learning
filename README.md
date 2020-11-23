## Zoneminder Docker
(Current version: 1.34)

### About
This is an easy to run dockerized image of [ZoneMinder](https://github.com/ZoneMinder/zoneminder) along with the the [ZM Event Notification Server](https://github.com/pliablepixels/zmeventnotification) and its machine learning subsystem (which is disabled by default but can be enabled by a simple configuration).  

The configuration settings that are needed for this implementation of Zoneminder are pre-applied and do not need to be changed on the first run of Zoneminder.

This verson will now upgrade from previous versions.

You can donate [here](https://www.paypal.com/us/cgi-bin/webscr?cmd=_s-xclick&amp;hosted_button_id=EJGPC7B5CS66E).

### Support
This docker was developed and is currently supported on Unraid.  You are free to use it on other platforms, but there is no way I can reproduce or troubleshoot any issues when used on other platforms.

Go to the Zoneminder Forum [here](https://forums.zoneminder.com/) for support.

### Installation
Install the docker by going to a command line and enter the command:

```bash
docker pull dlandon/zoneminder
```

This will pull the zoneminder docker image.  Once it is installed you are ready to run the docker.

Before you run the image, feel free to read configuration section below to customize various settings

To run Zoneminder:

```bash
docker run -d --name="Zoneminder" \
--net="bridge" \
--privileged="true" \
-p 8443:443/tcp \
-p 9000:9000/tcp \
-e TZ="America/New_York" \
-e SHMEM="50%" \
-e PUID="99" \
-e PGID="100" \
-e INSTALL_HOOK="0" \
-e INSTALL_FACE="0" \
-e INSTALL_TINY_YOLOV3="0" \
-e INSTALL_YOLOV3="0" \
-e INSTALL_TINY_YOLOV4="0" \
-e INSTALL_YOLOV4="0" \
-e MULTI_PORT_START="0" \
-e MULTI_PORT_END="0" \
-v "/mnt/Zoneminder":"/config":rw \
-v "/mnt/Zoneminder/data":"/var/cache/zoneminder":rw \
dlandon/zoneminder
```

For http:// access use: -p 8080:80/tcp

**Note**: If you have opted to install face recognition, and/or have opted to download the yolo models, it takes time.
Face recognition in particular can take several minutes (or more). Once the `docker run` command above completes, you may not be able to access ZoneMinder untill all the downloads are done. To follow along the installation progress, do a `docker logs -f Zoneminder` to see the syslog for the container that was created above.

### Subsequent runs

You can start/stop/restart the container anytime. You don't need to run the command above every time. If you have already created the container once (by the `docker run` command above), you can simply do a `docker stop Zoneminder` to stop it and a `docker start Zoneminder` to start it anytime (or do a `docker restart Zoneminder`)

#### Customization

- Set `INSTALL_HOOK="1"` to install the hook processing packages and run setup.py to prepare the hook processing.  The initial installation can take a long time.
- Set `INSTALL_FACE="1"` to install face recognition packages.  The initial installation can take a long time.
- Set `INSTALL_TINY_YOLOV3="1"` to install the tiny yolo v3 hook processing files.
- Set `INSTALL_YOLOV3="1"` to install the yolo v3 hook processing files.
- Set `INSTALL_TINY_YOLOV4="1"` to install the tiny yolo v4 hook processing files.
- Set `INSTALL_YOLOV4="1"` to install the yolo v4 hook processing files.
- Set `MULTI_PORT_START` and `MULTI_PORT_END` to define a port range for ES multi-port operation.
- The commands above use a host path of `/mnt/Zoneminder` to map the container config and cache directories. This is going to be persistent directory that will retain data across container/image stop/restart/deletes. ZM mysql/other config data/event files/etc are kept here. You can change this to any directory in your host path that you want to.

#### User Script

You can enable a custom user script that will run every time the container is started.

Put your script in the /mnt/Zoneminder/ folder and name it userscript.sh.  The script will be executed each time the Docker is started before Zoneminder is started.  Be sure to chmod +x userscript.sh so the script is executable. 

- Set `ADVANCED_SCRIPT="1"` environment variable to enable your script

#### Adding Nvidia GPU support to the Zoneminder.

You will have to install support for your graphics card.  If you are using Unraid, install the Nvidia plugin and follow these [instructions](https://forums.unraid.net/topic/77813-plugin-linuxserverio-unraid-nvidia/?tab=comments#comment-719665).  On other systems install the Nvidia Docker, see [here](https://medium.com/@adityathiruvengadam/cuda-docker-%EF%B8%8F-for-deep-learning-cab7c2be67f9).

After you confirm the graphics card is seen by the Zoneminder docker, you can then compile opencv with GPU support.  Be sure your Zoneminder docker can see the graphics card.  Read the open.cv script for instructions on how to download the packages needed for compiling opencv.  You will need to get a developer account for some of the packages because of licensing.  Get into the docker command line and do this once you have the packages:
- cd /config
- ./opencv.sh

This will compile the opencv with GPU support.  It takes a LONG time.  You should then have GPU support.

You will have to install the CuDNN runtime yourself based on your particular setup.

#### Post install configuration and caveats

- After successful installation, please refer to the [ZoneMinder](https://zoneminder.readthedocs.io/en/stable/), [Event Server and Machine Learning](https://zmeventnotification.readthedocs.io/en/latest/index.html) configuration guides from the authors of these components to set it up to your needs. Specifically, if you are using the Event Server and the Machine learning hooks, you will need to customize `/etc/zm/zmeventnotification.ini` and `/etc/zm/objectconfig.ini`

- Note that by default, this docker build runs ZM on port 443 inside the docker container and maps it to port 8443 for the outside world. Therefore, if you are configuring `/etc/zm/objectconfig.ini` or `/etc/zm/zmeventnotification.ini` remember to use `https://localhost:443/<etc>` as the base URL

- Push notifications with images will not work unless you replace the self-signed certificates that are auto-generated. Feel free to use the excellent and free [LetsEncrypt](https://letsencrypt.org) service if you'd like.

#### Usage

To access the Zoneminder gui, browse to: `https://<your host ip>:8443/zm` or `http://<your host ip>:8080/zm` if `-p 8080:80/tcp` is specified.

The zmNinja Event Notification Server is accessed at port `9000`.  Security with a self signed certificate is enabled.  You may have to install the certificate on iOS devices for the event notification to work properly.

#### Troubleshooting when the docker fails

If you have a situation where the docker fails to start, you can set an environemtnt variable when the docker is started and MySql and Zoneminder will not be started.  This will keep the docker running so you can get into a command line in the docker and troubleshoot the problem.

Create an environment variable:
NO_START_ZM="1"

MySql and Zoneminder will not be started.

Get into a command line in the docker and troubleshoot your issue by using the following commands to start MySql and zonemonder and fix any errors/problems with them starting.

service mysql start

service zoneminder start
