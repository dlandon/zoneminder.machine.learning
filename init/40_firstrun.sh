#!/bin/bash
#
# 40_firstrun.sh
#
#
# Github URL for opencv zip file download.
# Current default is to pull the version 4.3.0 release.
#
# Search for config files, if they don't exist, create the default ones
if [ ! -d /config/conf ]; then
	echo "Creating conf folder"
	mkdir /config/conf
else
	echo "Using existing conf folder"
fi

if [ -f /root/zm.conf ]; then
	echo "Moving zm.conf to config folder"
	mv /root/zm.conf /config/conf/zm.default
	cp /etc/zm/conf.d/README /config/conf/README
else
	echo "File zm.conf already moved"
fi

# Get the latest ES bundle
cd /root
rm -rf zmeventnotification
wget -q https://github.com/dlandon/zoneminder/raw/master/zmeventnotification/EventServer.tgz
if [ -f EventServer.tgz ]; then
	tar -xf EventServer.tgz
	rm EventServer.tgz
else
	echo "Error: Cannot download the ES server bundle"
fi

# Handle the zmeventnotification.ini file
if [ -f /root/zmeventnotification/zmeventnotification.ini ]; then
	echo "Moving zmeventnotification.ini"
	cp /root/zmeventnotification/zmeventnotification.ini /config/zmeventnotification.ini.default
	if [ ! -f /config/zmeventnotification.ini ]; then
		mv /root/zmeventnotification/zmeventnotification.ini /config/zmeventnotification.ini
	else
		rm -rf /root/zmeventnotification/zmeventnotification.ini
	fi
else
	echo "File zmeventnotification.ini already moved"
fi

# Handle the secrets.ini file
if [ -f /root/zmeventnotification/secrets.ini ]; then
	echo "Moving secrets.ini"
	cp /root/zmeventnotification/secrets.ini /config/secrets.ini.default
	if [ ! -f /config/secrets.ini ]; then
		mv /root/zmeventnotification/secrets.ini /config/secrets.ini
	else
		rm -rf /root/zmeventnotification/secrets.ini
	fi
else
	echo "File secrets.ini already moved"
fi

# Create opencv folder if it doesn't exist
if [ ! -d /config/opencv ]; then
	echo "Creating opencv folder in config folder"
	mkdir /config/opencv
fi

# Handle the opencv.sh file
if [ -f /root/zmeventnotification/opencv.sh ]; then
	echo "Moving opencv.sh"
	cp /root/zmeventnotification/opencv.sh /config/opencv/opencv.sh.default
	if [ ! -f /config/opencv/opencv.sh ]; then
		mv /root/zmeventnotification/opencv.sh /config/opencv/opencv.sh
	else
		rm -rf /root/zmeventnotification/opencv.sh
	fi
else
	echo "File opencv.sh already moved"
fi

# Handle the debug_opencv.sh file
if [ -f /root/zmeventnotification/debug_opencv.sh ]; then
	echo "Moving debug_opencv.sh"
	mv /root/zmeventnotification/debug_opencv.sh /config/opencv/debug_opencv.sh
else
	echo "File debug_opencv.sh already moved"
fi

if [ ! -f /config/opencv/opencv_ok ]; then
	echo "no" > /config/opencv/opencv_ok
fi

# Handle the zmeventnotification.pl
if [ -f /root/zmeventnotification/zmeventnotification.pl ]; then
	echo "Moving the event notification server"
	mv /root/zmeventnotification/zmeventnotification.pl /usr/bin
	chmod +x /usr/bin/zmeventnotification.pl 2>/dev/null
else
	echo "Event notification server already moved"
fi

# Handle the pushapi_pushover.py
if [ -f /root/zmeventnotification/pushapi_pushover.py ]; then
	echo "Moving the pushover api"
	mkdir -p /var/lib/zmeventnotification/bin/
	mv /root/zmeventnotification/pushapi_pushover.py /var/lib/zmeventnotification/bin/
	chmod +x /var/lib/zmeventnotification/bin/pushapi_pushover.py 2>/dev/null
else
	echo "Pushover api already moved"
fi

# Move ssmtp configuration if it doesn't exist
if [ ! -d /config/ssmtp ]; then
	echo "Moving ssmtp to config folder"
	cp -p -R /etc/ssmtp/ /config/
else
	echo "Using existing ssmtp folder"
fi

# Move mysql database if it doesn't exit
if [ ! -d /config/mysql/mysql ]; then
	echo "Moving mysql to config folder"
	rm -rf /config/mysql
	cp -p -R /var/lib/mysql /config/
else
	echo "Using existing mysql database folder"
fi

# files and directories no longer exposed at config.
rm -rf /config/perl5/
rm -rf /config/zmeventnotification/
rm -rf /config/zmeventnotification.pl
rm -rf /config/skins
rm -rf /config/zm.conf

# Create Control folder if it doesn't exist and copy files into image
if [ ! -d /config/control ]; then
	echo "Creating control folder in config folder"
	mkdir /config/control
else
	echo "Copy /config/control/ scripts to /usr/share/perl5/ZoneMinder/Control/"
	cp /config/control/*.pm /usr/share/perl5/ZoneMinder/Control/ 2>/dev/null
	chown root:root /usr/share/perl5/ZoneMinder/Control/* 2>/dev/null
	chmod 644 /usr/share/perl5/ZoneMinder/Control/* 2>/dev/null
fi

# Copy conf files if there are any
if [ -d /config/conf ]; then
	echo "Copy /config/conf/ scripts to /etc/zm/conf.d/"
	cp /config/conf/*.conf /etc/zm/conf.d/ 2>/dev/null
	chown root:root /etc/zm/conf.d* 2>/dev/null
	chmod 640 /etc/conf.d/* 2>/dev/null
fi

echo "Creating symbolink links"
# security certificate keys
rm -rf /etc/apache2/ssl/zoneminder.crt
ln -sf /config/keys/cert.crt /etc/apache2/ssl/zoneminder.crt
rm -rf /etc/apache2/ssl/zoneminder.key
ln -sf /config/keys/cert.key /etc/apache2/ssl/zoneminder.key
mkdir -p /var/lib/zmeventnotification/push
mkdir -p /config/push
rm -rf /var/lib/zmeventnotification/push/tokens.txt
ln -sf /config/push/tokens.txt /var/lib/zmeventnotification/push/tokens.txt

# ssmtp
rm -r /etc/ssmtp 
ln -s /config/ssmtp /etc/ssmtp

# mysql
rm -r /var/lib/mysql
ln -s /config/mysql /var/lib/mysql

# Set ownership for unRAID
PUID=${PUID:-99}
PGID=${PGID:-100}
usermod -o -u $PUID nobody
usermod -g $PGID nobody
usermod -d /config nobody

# Set ownership for mail
usermod -a -G mail www-data

# Change some ownership and permissions
chown -R mysql:mysql /config/mysql
chown -R mysql:mysql /var/lib/mysql
chown -R $PUID:$PGID /config/conf
chmod 777 /config/conf
chmod 666 /config/conf/*
chown -R $PUID:$PGID /config/control
chmod 777 /config/control
chmod 666 -R /config/control/
chown -R $PUID:$PGID /config/ssmtp
chmod -R 777 /config/ssmtp
chown -R $PUID:$PGID /config/zmeventnotification.*
chmod 666 /config/zmeventnotification.*
chown -R $PUID:$PGID /config/secrets.ini
chmod 666 /config/secrets.ini
chown -R $PUID:$PGID /config/opencv
chmod 777 /config/opencv
chmod 666 /config/opencv/*
chown -R $PUID:$PGID /config/keys
chmod 777 /config/keys
chmod 666 /config/keys/*
chown -R www-data:www-data /config/push/
chown -R www-data:www-data /var/lib/zmeventnotification/
chmod +x /config/opencv/opencv.sh
chmod +x /config/opencv/debug_opencv.sh
chmod +x /config/opencv/opencv.sh.default

# Create events folder
if [ ! -d /var/cache/zoneminder/events ]; then
	echo "Create events folder"
	mkdir /var/cache/zoneminder/events
	chown -R www-data:www-data /var/cache/zoneminder/events
	chmod -R 777 /var/cache/zoneminder/events
else
	echo "Using existing data directory for events"

	# Check the ownership on the /var/cache/zoneminder/events directory
	if [ `stat -c '%U:%G' /var/cache/zoneminder/events` != 'www-data:www-data' ]; then
		echo "Correcting /var/cache/zoneminder/events ownership..."
		chown -R www-data:www-data /var/cache/zoneminder/events
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
	chown -R www-data:www-data /var/cache/zoneminder/images
	chmod -R 777 /var/cache/zoneminder/images
else
	echo "Using existing data directory for images"

	# Check the ownership on the /var/cache/zoneminder/images directory
	if [ `stat -c '%U:%G' /var/cache/zoneminder/images` != 'www-data:www-data' ]; then
		echo "Correcting /var/cache/zoneminder/images ownership..."
		chown -R www-data:www-data /var/cache/zoneminder/images
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
	chown -R www-data:www-data /var/cache/zoneminder/temp
	chmod -R 777 /var/cache/zoneminder/temp
else
	echo "Using existing data directory for temp"

	# Check the ownership on the /var/cache/zoneminder/temp directory
	if [ `stat -c '%U:%G' /var/cache/zoneminder/temp` != 'www-data:www-data' ]; then
		echo "Correcting /var/cache/zoneminder/temp ownership..."
		chown -R www-data:www-data /var/cache/zoneminder/temp
	fi

	# Check the permissions on the /var/cache/zoneminder/temp directory
	if [ `stat -c '%a' /var/cache/zoneminder/temp` != '777' ]; then
		echo "Correcting /var/cache/zoneminder/temp permissions..."
		chmod -R 777 /var/cache/zoneminder/temp
	fi
fi

# Create cache folder
if [ ! -d /var/cache/zoneminder/cache ]; then
	echo "Create cache folder"
	mkdir /var/cache/zoneminder/cache
	chown -R www-data:www-data /var/cache/zoneminder/cache
	chmod -R 777 /var/cache/zoneminder/cache
else
	echo "Using existing data directory for cache"

	# Check the ownership on the /var/cache/zoneminder/cache directory
	if [ `stat -c '%U:%G' /var/cache/zoneminder/cache` != 'www-data:www-data' ]; then
		echo "Correcting /var/cache/zoneminder/cache ownership..."
		chown -R www-data:www-data /var/cache/zoneminder/cache
	fi

	# Check the permissions on the /var/cache/zoneminder/cache directory
	if [ `stat -c '%a' /var/cache/zoneminder/cache` != '777' ]; then
		echo "Correcting /var/cache/zoneminder/cache permissions..."
		chmod -R 777 /var/cache/zoneminder/cache
	fi
fi

# set user crontab entries
crontab -r -u root
if [ -f /config/cron ]; then
	crontab -l -u root | cat - /config/cron | crontab -u root -
fi

# Symbolink for /config/zmeventnotification.ini
ln -sf /config/zmeventnotification.ini /etc/zm/zmeventnotification.ini
chown www-data:www-data /etc/zm/zmeventnotification.ini

# Symbolink for /config/secrets.ini
ln -sf /config/secrets.ini /etc/zm/

# Fix memory issue
echo "Setting shared memory to : $SHMEM of `awk '/MemTotal/ {print $2}' /proc/meminfo` bytes"
umount /dev/shm
mount -t tmpfs -o rw,nosuid,nodev,noexec,relatime,size=${SHMEM} tmpfs /dev/shm

# Set multi-ports in apache2 for ES.
# Start with default configuration.
cp /etc/apache2/ports.conf.default /etc/apache2/ports.conf
cp /etc/apache2/sites-enabled/default-ssl.conf.default /etc/apache2/sites-enabled/default-ssl.conf

if [ $((MULTI_PORT_START)) -gt 0 ] && [ $((MULTI_PORT_END)) -gt $((MULTI_PORT_START)) ]; then

	echo "Setting ES multi-port range from ${MULTI_PORT_START} to ${MULTI_PORT_END}."

	ORIG_VHOST="_default_:443"

	NEW_VHOST=${ORIG_VHOST}
	PORT=${MULTI_PORT_START}
	while [[ ${PORT} -le ${MULTI_PORT_END} ]]; do
	    egrep -sq "Listen ${PORT}" /etc/apache2/ports.conf || echo "Listen ${PORT}" >> /etc/apache2/ports.conf
	    NEW_VHOST="${NEW_VHOST} _default_:${PORT}"
	    PORT=$(($PORT + 1))
	done

	perl -pi -e "s/${ORIG_VHOST}/${NEW_VHOST}/ if (/<VirtualHost/);" /etc/apache2/sites-enabled/default-ssl.conf
else
	if [ $((MULTI_PORT_START)) -ne 0 ];then
		echo "Multi-port error start ${MULTI_PORT_START}, end ${MULTI_PORT_END}."
	fi
fi

# Install hook packages, if enabled
if [ "$INSTALL_HOOK" == "1" ]; then
	echo "Installing machine learning modules & hooks..."

	if [ ! -f /root/setup.py ]; then
		# If hook folder exists, copy files into image
		if [ ! -d /config/hook ]; then
			echo "Creating hook folder in config folder"
			mkdir /config/hook
		fi

		# Python modules needed for hook processing
		apt-get -y install python3-pip cmake
		apt-get -y install libopenblas-dev liblapack-dev libblas-dev

		# pip3 will take care of installing dependent packages
		pip3 install future
		pip3 install /root/zmeventnotification

		cd ~
	    rm -rf /root/zmeventnotification/zmes_hook_helpers
	fi

	# Download models files
	if [ "$INSTALL_TINY_YOLOV3" == "1" ]; then
		if [ ! -d /config/hook/models/tinyyolov3 ]; then
			echo "Downloading tiny yolo models and configurations..."
			mkdir -p /config/hook/models/tinyyolov3
			wget https://pjreddie.com/media/files/yolov3-tiny.weights -O /config/hook/models/tinyyolov3/yolov3-tiny.weights
			wget https://raw.githubusercontent.com/pjreddie/darknet/master/cfg/yolov3-tiny.cfg -O /config/hook/models/tinyyolov3/yolov3-tiny.cfg
			wget https://raw.githubusercontent.com/pjreddie/darknet/master/data/coco.names -O /config/hook/models/tinyyolov3/coco.names
		else
			echo "Tiny Yolo V3 files have already been downloaded, skipping..."
		fi
	fi

	if [ "$INSTALL_YOLOV3" == "1" ]; then
		if [ ! -d /config/hook/models/yolov3 ]; then
			echo "Downloading yolo models and configurations..."
			mkdir -p /config/hook/models/yolov3
			wget https://raw.githubusercontent.com/pjreddie/darknet/master/cfg/yolov3.cfg -O /config/hook/models/yolov3/yolov3.cfg
			wget https://raw.githubusercontent.com/pjreddie/darknet/master/data/coco.names -O /config/hook/models/yolov3/coco.names
			wget https://pjreddie.com/media/files/yolov3.weights -O /config/hook/models/yolov3/yolov3.weights
		else
			echo "Yolo V3 files have already been downloaded, skipping..."
	    fi
	fi

	if [ "$INSTALL_TINY_YOLOV4" == "1" ]; then
		if [ ! -d /config/hook/models/tinyyolov4 ]; then
			echo "Downloading tiny yolo models and configurations..."
			mkdir -p /config/hook/models/tinyyolov4
			wget https://github.com/AlexeyAB/darknet/releases/download/darknet_yolo_v4_pre/yolov4-tiny.weights -O /config/hook/models/tinyyolov4/yolov4-tiny.weights
			wget https://raw.githubusercontent.com/AlexeyAB/darknet/master/cfg/yolov4-tiny.cfg -O /config/hook/models/tinyyolov4/yolov4-tiny.cfg
			wget https://raw.githubusercontent.com/pjreddie/darknet/master/data/coco.names -O /config/hook/models/tinyyolov4/coco.names
		else
			echo "Tiny Yolo V4 files have already been downloaded, skipping..."
		fi
	fi

	if [ "$INSTALL_YOLOV4" == "1" ]; then
		if [ ! -d /config/hook/models/yolov4 ]; then
			echo "Downloading yolo models and configurations..."
			mkdir -p /config/hook/models/yolov4
			wget https://raw.githubusercontent.com/AlexeyAB/darknet/master/cfg/yolov4.cfg -O /config/hook/models/yolov4/yolov4.cfg
			wget https://raw.githubusercontent.com/pjreddie/darknet/master/data/coco.names -O /config/hook/models/yolov4/coco.names
			wget https://github.com/AlexeyAB/darknet/releases/download/darknet_yolo_v3_optimal/yolov4.weights -O /config/hook/models/yolov4/yolov4.weights
		else
			echo "Yolo V4 files have already been downloaded, skipping..."
	    fi
	fi

	# Handle the objectconfig.ini file
	if [ -f /root/zmeventnotification/objectconfig.ini ]; then
		echo "Moving objectconfig.ini"
		cp /root/zmeventnotification/objectconfig.ini /config/hook/objectconfig.ini.default
		if [ ! -f /config/hook/objectconfig.ini ]; then
			mv /root/zmeventnotification/objectconfig.ini /config/hook/objectconfig.ini
		else
			rm -rf /root/zmeventnotification/objectconfig.ini
		fi
	else
		echo "File objectconfig.ini already moved"
	fi

	# Handle the config_upgrade script
	if [ -f /root/zmeventnotification/config_upgrade.py ]; then
		echo "Moving config_upgrade.py"
		mv /root/zmeventnotification/config_upgrade.py /config/hook/config_upgrade.py
		mv /root/zmeventnotification/config_upgrade.sh /config/hook/config_upgrade.sh
		chmod +x /config/hook/config_upgrade.*
	else
		echo "config_upgrade.py script not found"
	fi

	# Handle the zm_event_start.sh file
	if [ -f /root/zmeventnotification/zm_event_start.sh ]; then
		echo "Moving zm_event_start.sh"
		mv /root/zmeventnotification/zm_event_start.sh /config/hook/zm_event_start.sh
	else
		echo "File zm_event_start.sh already moved"
	fi

	# Handle the zm_event_end.sh file
	if [ -f /root/zmeventnotification/zm_event_end.sh ]; then
		echo "Moving zm_event_end.sh"
		mv /root/zmeventnotification/zm_event_end.sh /config/hook/zm_event_end.sh
	else
		echo "File zm_event_end.sh already moved"
	fi

	# Handle the zm_detect.py file
	if [ -f /root/zmeventnotification/zm_detect.py ]; then
		echo "Moving zm_detect.py"
		mv /root/zmeventnotification/zm_detect.py /config/hook/zm_detect.py
	else
		echo "File zm_detect.py already moved"
	fi

	# Handle the zm_train_faces.py file
	if [ -f /root/zmeventnotification/zm_train_faces.py ]; then
		echo "Moving zm_train_faces.py"
		mv /root/zmeventnotification/zm_train_faces.py /config/hook/zm_train_faces.py
	else
		echo "File zm_train_faces.py already moved"
	fi

	# Symbolic link for models in /config
	rm -rf /var/lib/zmeventnotification/models
	ln -sf /config/hook/models /var/lib/zmeventnotification/models
	chown -R www-data:www-data /var/lib/zmeventnotification/models

	# Symbolic link for known_faces in /config
	rm -rf /var/lib/zmeventnotification/known_faces
	ln -sf /config/hook/known_faces /var/lib/zmeventnotification/known_faces
	chown -R www-data:www-data /var/lib/zmeventnotification/known_faces

	# Symbolic link for unknown_faces in /config
	rm -rf /var/lib/zmeventnotification/unknown_faces
	ln -sf /config/hook/unknown_faces /var/lib/zmeventnotification/unknown_faces
	chown -R www-data:www-data /var/lib/zmeventnotification/unknown_faces

	# Symbolic link for misc in /config
	rm -rf /var/lib/zmeventnotification/misc
	ln -sf /config/hook/misc /var/lib/zmeventnotification/misc
	chown -R www-data:www-data /var/lib/zmeventnotification/misc

	# Create misc folder if it doesn't exist
	if [ ! -d /config/hook/misc ]; then
		echo "Creating hook/misc folder in config folder"
		mkdir -p /config/hook/misc
	fi

	# Symbolic link for coral_edgetpu in /config
	rm -rf /var/lib/zmeventnotification/coral_edgetpu
	ln -sf /config/hook/coral_edgetpu /var/lib/zmeventnotification/coral_edgetpu
	chown -R www-data:www-data /var/lib/zmeventnotification/coral_edgetpu

	# Create coral_edgetpu folder if it doesn't exist
	if [ ! -d /config/hook/coral_edgetpu ]; then
		echo "Creating hook/coral_edgetpu folder in config folder"
		mkdir -p /config/hook/coral_edgetpu
	fi

	# Symbolic link for hook files in /config
	mkdir -p /var/lib/zmeventnotification/bin
	ln -sf /config/hook/zm_detect.py /var/lib/zmeventnotification/bin/zm_detect.py
	ln -sf /config/hook/zm_train_faces.py /var/lib/zmeventnotification/bin/zm_train_faces.py
	ln -sf /config/hook/zm_event_start.sh /var/lib/zmeventnotification/bin/zm_event_start.sh
	ln -sf /config/hook/zm_event_end.sh /var/lib/zmeventnotification/bin/zm_event_end.sh
	chmod +x /var/lib/zmeventnotification/bin/*
	ln -sf /config/hook/objectconfig.ini /etc/zm/

	if [ "$INSTALL_FACE" == "1" ] && [ -f /root/zmeventnotification/setup.py ]; then
		# Create known_faces folder if it doesn't exist
		if [ ! -d /config/hook/known_faces ]; then
			echo "Creating hook/known_faces folder in config folder"
			mkdir -p /config/hook/known_faces
		fi

		# Create known_faces folder if it doesn't exist
		if [ ! -d /config/hook/known_faces ]; then
			echo "Creating hook/known_faces folder in config folder"
			mkdir -p /config/hook/known_faces
		fi

		# Create unknown_faces folder if it doesn't exist
		if [ ! -d /config/hook/unknown_faces ]; then
			echo "Creating hook/unknown_faces folder in config folder"
			mkdir -p /config/hook/unknown_faces
		fi

		# Install for face recognition
 		pip3 install face_recognition
	fi

	# Set hook folder permissions
	chown -R $PUID:$PGID /config/hook
	chmod -R 777 /config/hook

	echo "Hook installation completed"

	# Compile opencv
	echo "Compiling opencv - this will take a while..."
	if [ -f /config/opencv/opencv_ok ] && [ `cat /config/opencv/opencv_ok` = 'yes' ]; then
		if [ ! -f /root/setup.py ]; then
			if [ -x /config/opencv/opencv.sh ]; then
				/config/opencv/opencv.sh quiet >/dev/null
			fi
		fi
	else
		if [ -f /root/opencv_compile.sh ]; then
			chmod +x /root/opencv_compile.sh
			/root/opencv_compile.sh >/dev/null
		fi
	fi

	mv /root/zmeventnotification/setup.py /root/setup.py
fi

echo "Starting services..."
service apache2 start
if [ "$NO_START_ZM" != "1" ]; then
	service mysql start

	# Update the database if necessary
	zmupdate.pl -nointeractive
	zmupdate.pl -f

	service zoneminder start
else
	echo "MySql and Zoneminder not started."
fi
