#!/bin/bash
#
# 05_set_the_time.sh
#

# Get docker env timezone and set system timezone
if [[ $(cat /etc/timezone) != "$TZ" ]] ; then
	echo "Setting the timezone to : $TZ"
	echo $TZ > /etc/timezone
	ln -fs /usr/share/zoneinfo/$TZ /etc/localtime
	dpkg-reconfigure tzdata
	echo "Date: `date`"
	sed -i "s|^date.timezone =.*$|date.timezone = ${TZ}|" /etc/php/7.0/apache2/php.ini
fi
