#!/bin/bash

	# Search for config files, if they don't exist, copy the default ones
	if [ ! -f /config/zm.conf ]; then
		echo "Copying zm.conf"
		cp /root/zm.conf /config/zm.conf
	else
		echo "File zm.conf already exists"
	fi

	# Copy mysql database if it doesn't exit
	if [ ! -d /config/mysql/mysql ]; then
		echo "Moving mysql to config folder"
		rm -rf /config/mysql
		cp -p -R /var/lib/mysql /config/
	else
		echo "Using existing mysql database"
	fi

	if [ ! -d /config/perl5 ]; then
		echo "Moving perl data folder to config folder"
		mkdir /config/perl5
	else
		echo "Using existing perl data directory"
	fi
	# Move the current ZoneMinder perl directory
	cp -R -p /usr/share/perl5/ZoneMinder /config/perl5/

	if [ ! -d /config/skins ]; then
		echo "Moving skins folder to config folder"
		mkdir /config/skins
		cp -R -p /usr/share/zoneminder/www/skins /config/
	else
		echo "Using existing skins directory"
	fi

	echo "Creating symbolink links"
	rm -r /var/lib/mysql
	rm -r /etc/zm
	rm -r /usr/share/perl5/ZoneMinder
	rm -r /usr/share/zoneminder/www/skins
	ln -s /config/mysql /var/lib/mysql
	ln -s /config /etc/zm
	ln -s /config/perl5/ZoneMinder /usr/share/perl5/ZoneMinder
	ln -s /config/skins /usr/share/zoneminder/www/skins

	# Set ownership for unRAID
	PUID=${PUID:-99}
	PGID=${PGID:-100}
	usermod -o -u $PUID nobody
	usermod -g $PGID nobody
	usermod -d /config nobody
	chown -R nobody:users /config
	chown -R mysql:mysql /config/mysql
	chown -R mysql:mysql /var/lib/mysql
	chmod -R go+rw /config

	# Create event folder
	if [ ! -d /var/cache/zoneminder/events ]; then
		echo "Create events folder"
		mkdir /var/cache/zoneminder/events
		chown -R root:www-data /var/cache/zoneminder/events
		chmod -R go+rw /var/cache/zoneminder/events
	else
		echo "Using existing data directory for events"
	fi

	# Create images folder
	if [ ! -d /var/cache/zoneminder/images ]; then
		echo "Create images folder"
		mkdir /var/cache/zoneminder/images
		chown -R root:www-data /var/cache/zoneminder/images
		chmod -R go+rw /var/cache/zoneminder/images
	else
		echo "Using existing data directory for images"
	fi

	# Create temp folder
	if [ ! -d /var/cache/zoneminder/temp ]; then
		echo "Create temp folder"
		mkdir /var/cache/zoneminder/temp
		chown -R root:www-data /var/cache/zoneminder/temp
		chmod -R go+rw /var/cache/zoneminder/temp
	else
		echo "Using existing data directory for temp"
	fi

	# Get docker env timezone and set system timezone
	export DEBCONF_NONINTERACTIVE_SEEN=true DEBIAN_FRONTEND=noninteractive
	echo "Setting the timezone to : $TZ"
	echo $TZ > /etc/timezone
	ln -fs /usr/share/zoneinfo/$TZ /etc/localtime
	dpkg-reconfigure tzdata
	echo "Date: `date`"
	sed -i "s|^date.timezone =.*$|date.timezone = ${TZ}|" /etc/php/7.0/apache2/php.ini

	# Fix memory issue
	echo "Setting shared memory to : $SHMEM of `awk '/MemTotal/ {print $2}' /proc/meminfo` bytes"
	umount /dev/shm
	mount -t tmpfs -o rw,nosuid,nodev,noexec,relatime,size=${SHMEM} tmpfs /dev/shm

	echo "Starting services"
	service mysql start
	# Update the database if necessary
	zmupdate.pl -nointeractive
	zmupdate.pl -f
	service apache2 start
	service zoneminder start
