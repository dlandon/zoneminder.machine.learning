# Zoneminder 1.30.4 for unRAID

The configuration settings that are needed for this implementation of Zoneminder are pre-applied and do not need to be changed on the first run of Zoneminder.

This verson will now upgrade from previous versions.

To run Zoneminder on unRAID:

docker run -d --name="Zoneminder" \
--net="bridge" \
--privileged="true" \
-p 8080:80/tcp \
-e TZ="America/New_York" \
-e SHMEM="50%" \
-e PUID="99" \
-e PGID="100" \
-v "/mnt/cache/appdata/Zoneminder":"/config":rw \
-v "/mnt/cache/appdata/Zoneminder/data":"/var/cache/zoneminder":rw \
zoneminder

Changes:

2017-09-26
- Change to dlandon/baseimage.

2017-09-24
- Modifications to dockerfile for auto build.

2017-09-15
- Add php-curl package.

2017-08-27
- Timezone setting adjustment and some minor changes to docker build.

2017-08-26
- Add appdata /control folder for PTZ scripts to be copied to the docker image.

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
