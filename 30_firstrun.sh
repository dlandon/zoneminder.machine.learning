#!/bin/bash
#
# 30_firstrun.sh
#

# Search for config files, if they don't exist, copy the default ones
if [ ! -f /config/zm.conf ]; then
	echo "Copying zm.conf"
	cp /root/zm.conf /config/zm.conf
else
	echo "File zm.conf already exists"
fi

# Move ssmtp configuration if it doesn't exist
if [ ! -d /config/ssmtp ]; then
	echo "Moving ssmtp to config folder"
	cp -p -R /etc/ssmtp/ /config/
else
	echo "Using existing ssmtp configuration"
fi

# Move mysql database if it doesn't exit
if [ ! -d /config/mysql/mysql ]; then
	echo "Moving mysql to config folder"
	rm -rf /config/mysql
	cp -p -R /var/lib/mysql /config/
else
	echo "Using existing mysql database"
fi

# Perl5 directory is no longer exposed at config.
rm -r /config/perl5/ 2>/dev/null

# Move skins folder if it doesn't exist
if [ ! -d /config/skins ]; then
	echo "Moving skins folder to config folder"
	mkdir /config/skins
	cp -R -p /usr/share/zoneminder/www/skins /config/
else
	echo "Using existing skins directory"
fi

echo "Creating symbolink links"
# ssmtp
rm -r /etc/ssmtp
ln -s /config/ssmtp /etc/ssmtp

# mysql
rm -r /var/lib/mysql
ln -s /config/mysql /var/lib/mysql

# zm.conf
rm -r /etc/zm/zm.conf
ln -sf /config/zm.conf /etc/zm/

# skins
rm -r /usr/share/zoneminder/www/skins
ln -s /config/skins /usr/share/zoneminder/www/skins

# Create event folder
if [ ! -d /var/cache/zoneminder/events ]; then
	echo "Create events folder"
	mkdir /var/cache/zoneminder/events
else
	echo "Using existing data directory for events"
fi

# Create images folder
if [ ! -d /var/cache/zoneminder/images ]; then
	echo "Create images folder"
	mkdir /var/cache/zoneminder/images
else
	echo "Using existing data directory for images"
fi

# Create temp folder
if [ ! -d /var/cache/zoneminder/temp ]; then
	echo "Create temp folder"
	mkdir /var/cache/zoneminder/temp
else
	echo "Using existing data directory for temp"
fi

# Set ownership for unRAID
PUID=${PUID:-99}
PGID=${PGID:-100}
usermod -o -u $PUID nobody
usermod -g $PGID nobody
usermod -d /config nobody
chown -R nobody:users /config
chown -R mysql:mysql /config/mysql
chown -R mysql:mysql /var/lib/mysql

# Set /config permissions
chmod -R go+rw /config

# Set /var/cache/zoneminder ownership
chown -R root:www-data /var/cache/zoneminder

# Set /var/cache/zoneminder permissions
chmod -R go+rw /var/cache/zoneminder

# Get docker env timezone and set system timezone
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
