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
if [ ! -f /config/zmeventnotification.ini ]; then
	echo "Copying zmeventnotification.ini"
	cp /root/zmeventnotification.ini /config/zmeventnotification.ini
else
	echo "File zmeventnotification.ini already exists"
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

# directories no longer exposed at config.
rm -rf /config/perl5/
rm -rf /config/zmeventnotification/

# Move skins folder if it doesn't exist
if [ ! -d /config/skins ]; then
	echo "Moving skins folder to config folder"
	mkdir /config/skins
	cp -R -p /usr/share/zoneminder/www/skins /config/
else
	echo "Using existing skins directory"
fi

# Create Control folder if it doesn't exist and copy files into image
if [ ! -d /config/control ]; then
	echo "Creating control folder in config folder"
	mkdir /config/control
else
	echo "Copy /config/control/ scripts to /usr/share/perl5/ZoneMinder/Control/"
	chown root:root /config/control/* 2>/dev/null
	chmod 644 /config/control/* 2>/dev/null
	cp /config/control/* /usr/share/perl5/ZoneMinder/Control/ 2>/dev/null
fi

echo "Creating symbolink links"
# security certificate keys
rm -rf /etc/apache2/ssl/zoneminder.crt
ln -sf /config/keys/cert.crt /etc/apache2/ssl/zoneminder.crt
rm -rf /etc/apache2/ssl/zoneminder.key
ln -sf /config/keys/cert.key /etc/apache2/ssl/zoneminder.key

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

# Set ownership for unRAID
PUID=${PUID:-99}
PGID=${PGID:-100}
usermod -o -u $PUID nobody
usermod -g $PGID nobody
usermod -d /config nobody

# Change some ownership and permissions
chown -R mysql:mysql /config/mysql
chown -R mysql:mysql /var/lib/mysql
chown $PUID:$PGID /config/zm.conf
chmod 666 /config/zm.conf
chown -R $PUID:$PGID /config/control
chmod -R 666 /config/control
chown -R $PUID:$PGID /config/ssmtp
chmod -R 666 /config/ssmtp
chown -R $PUID:$PGID /config/skins

# Create events folder
if [ ! -d /var/cache/zoneminder/events ]; then
	echo "Create events folder"
	mkdir /var/cache/zoneminder/events
	chown -R root:www-data /var/cache/zoneminder/events
	chmod -R 777 /var/cache/zoneminder/events
else
	echo "Using existing data directory for events"

	# Check the ownership on the /var/cache/zoneminder/events directory
	if [ `stat -c '%U:%G' /var/cache/zoneminder/events` != 'root:www-data' ]; then
		echo "Correcting /var/cache/zoneminder/events ownership..."
		chown -R root:www-data /var/cache/zoneminder/events
	fi

	# Check the permissions on the /var/cache/zoneminder/events directory
	if [ `stat -c '%a' /var/cache/zoneminder/events` != '777' ]; then
		echo "Correcting /var/cache/zoneminder/events permissions..."
		chmod -R 777 /var/cache/zoneminder/events
	fi
fi

# Create images folder
if [ ! -d /var/cache/zoneminder/images ]; then
	echo "Create images folder"
	mkdir /var/cache/zoneminder/images
	chown -R root:www-data /var/cache/zoneminder/images
	chmod -R 777 /var/cache/zoneminder/images
else
	echo "Using existing data directory for images"

	# Check the ownership on the /var/cache/zoneminder/images directory
	if [ `stat -c '%U:%G' /var/cache/zoneminder/images` != 'root:www-data' ]; then
		echo "Correcting /var/cache/zoneminder/images ownership..."
		chown -R root:www-data /var/cache/zoneminder/images
	fi

	# Check the permissions on the /var/cache/zoneminder/images directory
	if [ `stat -c '%a' /var/cache/zoneminder/images` != '777' ]; then
		echo "Correcting /var/cache/zoneminder/images permissions..."
		chmod -R 777 /var/cache/zoneminder/images
	fi
fi

# Create temp folder
if [ ! -d /var/cache/zoneminder/temp ]; then
	echo "Create temp folder"
	mkdir /var/cache/zoneminder/temp
	chown -R root:www-data /var/cache/zoneminder/temp
	chmod -R 777 /var/cache/zoneminder/temp
else
	echo "Using existing data directory for temp"

	# Check the ownership on the /var/cache/zoneminder/temp directory
	if [ `stat -c '%U:%G' /var/cache/zoneminder/temp` != 'root:www-data' ]; then
		echo "Correcting /var/cache/zoneminder/temp ownership..."
		chown -R root:www-data /var/cache/zoneminder/temp
	fi

	# Check the permissions on the /var/cache/zoneminder/temp directory
	if [ `stat -c '%a' /var/cache/zoneminder/temp` != '777' ]; then
		echo "Correcting /var/cache/zoneminder/temp permissions..."
		chmod -R 777 /var/cache/zoneminder/temp
	fi
fi

# set user crontab entries
crontab -r -u root
if [ -f /config/cron ]; then
	crontab -l -u root | cat - /config/cron | crontab -u root -
fi

# copy the zmeventnotification.ini file to /etc
cp /config/zmeventnotification.ini /etc/

# Fix memory issue
echo "Setting shared memory to : $SHMEM of `awk '/MemTotal/ {print $2}' /proc/meminfo` bytes"
umount /dev/shm
mount -t tmpfs -o rw,nosuid,nodev,noexec,relatime,size=${SHMEM} tmpfs /dev/shm

echo "Starting services"
service mysql start
# Update the database if necessary
zmupdate.pl -nointeractive
zmupdate.pl -f

a2enmod ssl >/dev/null
service apache2 start
service zoneminder start
