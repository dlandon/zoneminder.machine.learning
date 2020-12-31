#!/bin/bash
#
# Script to set up permissions on hardware devices for GPU support.
# Inspired by how the guys over at linuxserver did this for their Plex image:
# https://github.com/linuxserver/docker-plex/blob/master/root/etc/cont-init.d/50-gid-video
#

echo "Granting permissions on /dev/dri/* devices..."

FILES=$(find /dev/dri /dev/dvb -type c -print 2>/dev/null)

for i in $FILES
do
	VIDEO_GID=$(stat -c '%g' "$i")
	if id -G www-data | grep -qw "$VIDEO_GID"; then
		echo "The www-data user already has appropriate permissions on $i"
		touch /groupadd
	else
		if [ ! "${VIDEO_GID}" == '0' ]; then
			VIDEO_NAME=$(getent group "${VIDEO_GID}" | awk -F: '{print $1}')
			if [ -z "${VIDEO_NAME}" ]; then
				VIDEO_NAME="video$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c8)"
				groupadd "$VIDEO_NAME"
				groupmod -g "$VIDEO_GID" "$VIDEO_NAME"
				echo "Generated a new group called: $VIDEO_NAME with id: $VIDEO_GID to match existing group on: $i"
			fi
			usermod -a -G "$VIDEO_NAME" www-data
			echo "Added user www-data to group $VIDEO_NAME so that it has permission to use: $i"
			touch /groupadd
		fi
	fi
done

if [ -n "${FILES}" ] && [ ! -f "/groupadd" ]; then
	usermod -a -G root www-data
	echo "Added user www-data to root group for lack of a better option."
fi
