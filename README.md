# Zoneminder 1.32 for Unraid

The configuration settings that are needed for this implementation of Zoneminder are pre-applied and do not need to be changed on the first run of Zoneminder.

This verson will now upgrade from previous versions.

To run Zoneminder on unRAID:

docker run -d --name="Zoneminder" \
--net="bridge" \
--privileged="true" \
-p 8080:80/tcp \
-p 8443:443/tcp \
-p 9000:9000/tcp \
-e TZ="America/New_York" \
-e SHMEM="50%" \
-e PUID="99" \
-e PGID="100" \
-v "/mnt/cache/appdata/Zoneminder":"/config":rw \
-v "/mnt/cache/appdata/Zoneminder/data":"/var/cache/zoneminder":rw \
zoneminder

To access the Zoneminder gui: http://IP:8080/zm or https://IP:8443/zm

The zmNinja Event Notification Server is accessed at port 9000.  Security with a self signed certificate is enabled.  You may have to install the certificate on iOS devices for the event notification to work properly.

Changes:

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
