## Zoneminder Docker
(Current version: 1.34)

### About
This is an easy to run dockerized image of [ZoneMinder](https://github.com/ZoneMinder/zoneminder) along with the the [ZM Event Notification Server](https://github.com/pliablepixels/zmeventnotification) and its machine learning subsystem (which is disabled by default but can be enabled by a simple configuration).  

The configuration settings that are needed for this implementation of Zoneminder are pre-applied and do not need to be changed on the first run of Zoneminder.

This verson will now upgrade from previous versions.

You can donate [here](https://www.paypal.com/us/cgi-bin/webscr?cmd=_s-xclick&amp;hosted_button_id=EJGPC7B5CS66E).

### Support
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
-e INSTALL_TINY_YOLO="0" \
-e INSTALL_YOLO="0" \
-v "/mnt/Zoneminder":"/config":rw \
-v "/mnt/Zoneminder/data":"/var/cache/zoneminder":rw \
dlandon/zoneminder
```

For http:// access use: -p 8080:80/tcp

**Note**: If you have opted to install face recognition, and/or have opted to download the yolo models, it takes time.
Face recognition in particular can take several minutes (or more). Once the `docker run` command above completes, you may not be able to access ZoneMinder till all the downloads are done. To follow along the installation progress, do a `docker logs -f Zoneminder` to see the syslog for the container that was created above.

### Subsequent runs

You can start/stop/restart the container anytime. You don't need to run the command above every time. If you have already created the container once (by the `docker run` command above), you can simply do a `docker stop Zoneminder` to stop it and a `docker start Zoneminder` to start it anytime (or do a `docker restart Zoneminder`)

#### Customization

- Set `INSTALL_HOOK="1"` to install the hook processing packages and run setup.py to prepare the hook processing.  The initial installation can take a long time.
- Set `INSTALL_FACE="1"` to install face recognition packages.  The initial installation can take a long time.
- Set `INSTALL_TINY_YOLO="1"` to install the tiny yolo hook processing files.
- Set `INSTALL_YOLO="1"` to install the yolo hook processing files.
- The command above use a host path of `/mnt/Zoneminder` to map the container config and cache directories. This is going to be persistent directory that will retain data across container/image stop/restart/deletes. ZM mysql/other config data/event files/etc are kept here. You can change this to any directory in your host path that you want to.

#### Adding Nvidia GPU support to the Zoneminder.

You will have to install support for your graphics card.  If you are using Unraid, install the Nvidia plugin and follow these [instructions](https://forums.unraid.net/topic/77813-plugin-linuxserverio-unraid-nvidia/?tab=comments#comment-719665).  On other systems install the Nvidia Docker, see [here](https://medium.com/@adityathiruvengadam/cuda-docker-%EF%B8%8F-for-deep-learning-cab7c2be67f9).

After you confirm the graphics card is seen by the Zoneminder docker, you can then compile opencv with GPU support.  Be sure your Zoneminder docker can see the graphics card.  Get into the docker command line and do this:
- cd /config
- ./opencv.sh

This will compile the opencv with GPU support.  It takes a LONG time.  You should then have GPU support.

You will have to install the CuDNN runtime yourself based on your particular setup.

#### Post install configuration and caveats

- After successful installation, please refer to the [ZoneMinder](https://zoneminder.readthedocs.io/en/stable/), [Event Server and Machine Learning](https://zmeventnotification.readthedocs.io/en/latest/index.html) configuration guides from the authors of these components to set it up to your needs. Specifically, if you are using the Event Server and the Machine learning hooks, you will need to customize `/etc/zm/zmeventnotification.ini` and `/etc/zm/objectconfig.ini`

- Note that by default, this docker build runs ZM on port 443 inside the docker container and maps it to port 8443 for the outside world. Therefore, if you are configuring `/etc/zm/objectconfig.ini` or `/etc/zm/zmeventnotification.ini` remember to use `https://localhost:443/<etc>` as the base URL

- Push notifications with images will not work unless you replace the self-signed certificates that are auto-generated. Feel free to use the excellent and free [LetsEncrypt](https://letsencrypt.org) service if you'd like.

#### Usage

To access the Zoneminder gui, browse to: `https://<your host ip>:8443/zm`

The zmNinja Event Notification Server is accessed at port `9000`.  Security with a self signed certificate is enabled.  You may have to install the certificate on iOS devices for the event notification to work properly.

#### Change Log

2020-02-29
- Fix docker failure when it can't update.

2020-02-23
- Fix reboot apt update of cuda failing again.
- Set up unattended re-compile of opencv when docker updates.
- More opencv script changes.

2020-02-22
- Move all opencv stuff to /config/opencv/ folder.
- Fix reboot apt update of cuda failing.

2020-02-21
- Fix uninstall and install of hooks when updating ES.

2020-02-20
- Update zmNinja Event Notification Server to version 5.7.7.

2020-02-17
- Change detection of INSTALL_HOOK already being installed,

2020-02-16
- Update zmNinja Event Notification Server to version 5.7.4 and add opencv.sh compile script.
- Modify ES update to install a tar to update ES so a new docker does not have to be built whrn ES is updated.

2020-02-05
- Adjust /var/cache/zoneminder ownership to www-data:www-data.

2020-01-17
- Update Zoneminder to 1.34.

2020-01-10
- Update zmNinja Event Notification Server to version 5.4.

2019-12-01
- Fix ES file references to newer versions of zm_detect_wrapper.sh amnd zm_detect.py

2019-11-23
- Update zmNinja Event Notification Server to version 4.6.

2019-11-09
- Update zmNinja Event Notification Server to version 4.5.

2019-10-26
- Remove cambozola legacy browser support.

2019-10-05
- Update zmNinja Event Notification Server to version 4.4.

2019-09-21
- Fix /hook folder permission check.
- Remove ZM_PATH_ZMS update from defaults.

2019-09-19
- Update zmes_hook_helpers.

2019-09-17
- Additional changes for zmevent server installation.

2019-09-15
- Update README to make it more generic.
- Add INSTALL_YOLO and INSTALL_TINY_YOLO environment variables to download the model files for zmeventserver when hook processing is enabled.
- Update zmNinja Event Notification Server to version 4.2.

2019-09-05
- Fix update script.

2019-08-05
- Added pyzmutils and requests modules for hook processing.

2019-08-03
- Use pip3 for setup.py install of hook processing.

2019-07-30
- Update zmNinja Event Notification Server to version 4.1.

2019-07-19
- Update zmNinja Event Notification Server to version 3.9.

2019-06-09
- Update zmNinja Event Notification Server to version 3.8.

2019-05-12
- Update zmNinja Event Notification Server to version 3.7.

2019-04-27
- Add Net::MQTT::Simple::Auth perl library.

2019-04-26
- Add "INSTALL_FACE" environment variable to load face recognition package.

2019-04-25
- Add zmes_hook_helpers to docker image and change the hook installation.

2019-04-24
- Update zmNinja Event Notification Server to version 3.6.
- Add "INSTALL_HOOK" environment variable to load packages and run 'setup.py' for hook processing.

2019-04-21
- Update zmNinja Event Notification Server to version 3.5.

2019-04-16
- Update zmNinja Event Notification Server to version 3.4.

2019-04-05
- Fix: Minor adjustments to zmeventnotification.

2019-03-30
- Fix: Control file copy was copying the wrong file extension.

2019-03-27
- Add: Install vlc packages.

2019-03-25
- Update zmNinja Event Notification Server to version 3.3.

2019-03-04
- Additional work to support the zmeventnotification server face recognition.
- Fix typos.

2019-03-02
- Update zmNinja Event Notification Server to version 3.2.  Many changes to the paths for zmeventnotification and hook files.

2019-02-21
- Update zmNinja Event Notification Server to version 3.1.

2019-02-08
- Update zmNinja Event Notification Server to version 3.0.

2019-01-26
- Update zmNinja Event Notification Server configuration file.
- Re-enable port 80 for special situations.

2019-01-05
- Update zmNinja Event Notification Server to version 2.6.

2018-12-25
- Update zmNinja Event Notification Server to version 2.5.

2018-12-09
- Remove http:// access.  You can only access Zoneminder with htps://.  A self signed certificate is generated for you.
- Update Zoneminder to 1.32.3.

2018-11-14
- Adjustment to apache2 modules.

2018-11-08
- Update zmNinja Event Notification Server to version 2.4.

2018-11-02
- Update zmNinja Event Notification Server to version 2.2.

2018-10-29
- Add the ability to run a user script.

2018-10-28
- Fix weekly zmaudit cron job.
- Remove hook permissions setting.

2018-10-26
- Change handling of the defaut zmeventnotification.ini file copyiing to /config.
- Setup up 'hook' folder to copy files to the docker image for zmeventnotification 'hook' processing.

2018-10-25
- Update zmNinja Event Notification Server to version 2.1.
- More docker file cleanup.

2018-10-24
- Run zmaudit weekly by cron.  Zmaudit does not need to run continuously.

2018-10-19
- Add ability to specify the ServerName in apache2 for ssl certs.

2018-10-18
- Fix ssmtp issues

2018-10-15
- Some docker file cleanup.

2018-10-14
- Minor changes to zmeventnotification.ini and zmeventnotification.pl unique to the docker.

2018-10-13
- Update Zoneminder to 1.32.2.

2018-10-12
- Fixed an issue with zmaudit.pl failing to run after Zoneminder crashes.

2018-10-11
- Permission adjustments on config files.
- Minor apache tweaks.
- Cleanup dockerfile.

2018-10-09
- Update Zoneminder to 1.32.1.
- Update zmeventnotification to 2.0.
- Update php to 7.1.

2018-10-08
- Update Apache configuration.  Clear your browser cache if you have trouble viewng the Zoneminder webpage.

2018-05-13
- Update zmNinja Event Notification Server to version 1.0.
- Remove SSL_EVENTS environment variable.
- Put zmeventnotifications.ini in /config/ directory to configure the zmNinja Event Notification Server.
- Fix error when copying multiple control script files.

2018-03-31
- Set proper permissions when creating events/, images/, and temp/ directories.
- Adjust correcting of events/, images/, and temp/ diectory ownerships.

2018-03-14
- Fix data directory ownership and permissions corrections.

2018-03-04
- Update to phusion 10.0 image.

2018-02-15
- Add user cron entries.  The cron entries in the /config/cron file will be entered into the root crontab.

2018-02-08
- Add SSL_EVENTS environment variable to enable/disable ssl on zmevent notifications.

2018-02-06
- Add ssl certificate to zmNinja and apache for access using https.  A self signed certificate is genereated and can be replaced if you want to supply your own certificate.

2018-02-04
- Add zmNinja Event Notification Server for zmNinja on iOS and Android devices.

2018-01-21
- Add net-tools package.

2017-11-30
- Update base image.

2017-09-26
- Change to dlandon/baseimage - phusion 9.22.

2017-09-24
- Modifications to dockerfile for auto build.

2017-09-15
- Add php-curl package.

2017-08-27
- Timezone setting adjustment and some minor changes to docker build.

2017-08-26
- Add /config/control folder for PTZ scripts to be copied to the docker image.

2017-08-14
- More adjustments to fixing file permissions.

2017-07-23
- Allow apache to update.

2017-06-17
- Fix ownership and permissions of /var/cache/zoneminder folder if not correct.

2017-05-28
- Fix permissions on /config/data/ folders.

2017-05-09
- Update to version 1.30.4.

2017-05-06
- Perl scripts are no longer exposed at /config/.  They change on each version and can't be persistent.
- Add ssmtp package for email alerts.  Ssmtp configuration files are at /config/Zoneminder/ssmtp/.
- Add libav-tools package for missing avconv.
- Cleanup symlinks.
- Remove installation files from /root/.

2017-05-05
- Initial release.
- Fixed update so databases can now be upgraded in place.
