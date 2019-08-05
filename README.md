# Zoneminder 1.32 for Unraid

The configuration settings that are needed for this implementation of Zoneminder are pre-applied and do not need to be changed on the first run of Zoneminder.

This verson will now upgrade from previous versions.

To run Zoneminder on unRAID:

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
-v "/mnt/cache/appdata/Zoneminder":"/config":rw \
-v "/mnt/cache/appdata/Zoneminder/data":"/var/cache/zoneminder":rw \
zoneminder

Set INSTALL_HOOK="1" to install the hook processing packages and run setup.py to prepare the hook processing.

Set INSTALL_FACE="1" to install face recognition packages.

To access the Zoneminder gui: https://IP:8443/zm

The zmNinja Event Notification Server is accessed at port 9000.  Security with a self signed certificate is enabled.  You may have to install the certificate on iOS devices for the event notification to work properly.

Changes:

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
