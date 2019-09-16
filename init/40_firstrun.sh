#!/bin/bash
#
# 40_firstrun.sh
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

# Handle the zmeventnotification.ini & daemon files

if [ -f /root/zmeventnotification/zmeventnotification.pl ]; then
  echo "Moving the event notification server"
  mv /root/zmeventnotification/zmeventnotification.pl /usr/bin
  chmod +x /usr/bin/zmeventnotification.pl 2>/dev/null
else
  echo "Event notification server already moved"
fi

if [ -f /root/zmeventnotification.ini ]; then
  echo "Moving zmeventnotificatio]n.ini"
  cp /root/zmeventnotification.ini /config/zmeventnotification.ini.default
  if [ ! -f /config/zmeventnotification.ini ]; then
    mv /root/zmeventnotification.ini /config/zmeventnotification.ini
  else
    rm -rf /root/zmeventnotification.ini
  fi
else
  echo "File zmeventnotification.ini already moved"
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
chmod -R 666 /config/conf
chown -R $PUID:$PGID /config/control
chmod -R 666 /config/control
chown -R $PUID:$PGID /config/hook
chmod -R 777 /config/hook
chown -R $PUID:$PGID /config/ssmtp
chmod -R 777 /config/ssmtp
chown -R $PUID:$PGID /config/zmeventnotification.*
chmod -R 666 /config/zmeventnotification.*
chown -R $PUID:$PGID /config/keys
chmod -R 777 /config/keys
if [ -d /config/push ]; then
  chown -R www-data:www-data /config/push
  chmod 755 /config/push
  chmod 644 /config/push/*
fi

# Create events folder
if [ ! -d /var/cache/zoneminder/events ]; then
  echo "Create events folder"
  mkdir /var/cache/zoneminder/events
  chown -R root:www-data /var/cache/zoneminder/events
  chmod -R 777 /var/cache/zoneminder/events
else
  echo "Using existing data directory for events"

  # Check the ownership on the /var/cache/zoneminder/events directory
  if [ $(stat -c '%U:%G' /var/cache/zoneminder/events) != 'root:www-data' ]; then
    echo "Correcting /var/cache/zoneminder/events ownership..."
    chown -R root:www-data /var/cache/zoneminder/events
  fi

  # Check the permissions on the /var/cache/zoneminder/events directory
  if [ $(stat -c '%a' /var/cache/zoneminder/events) != '777' ]; then
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
  if [ $(stat -c '%U:%G' /var/cache/zoneminder/images) != 'root:www-data' ]; then
    echo "Correcting /var/cache/zoneminder/images ownership..."
    chown -R root:www-data /var/cache/zoneminder/images
  fi

  # Check the permissions on the /var/cache/zoneminder/images directory
  if [ $(stat -c '%a' /var/cache/zoneminder/images) != '777' ]; then
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
  if [ $(stat -c '%U:%G' /var/cache/zoneminder/temp) != 'root:www-data' ]; then
    echo "Correcting /var/cache/zoneminder/temp ownership..."
    chown -R root:www-data /var/cache/zoneminder/temp
  fi

  # Check the permissions on the /var/cache/zoneminder/temp directory
  if [ $(stat -c '%a' /var/cache/zoneminder/temp) != '777' ]; then
    echo "Correcting /var/cache/zoneminder/temp permissions..."
    chmod -R 777 /var/cache/zoneminder/temp
  fi
fi

# Create cache folder
if [ ! -d /var/cache/zoneminder/cache ]; then
  echo "Create cache folder"
  mkdir /var/cache/zoneminder/cache
  chown -R root:www-data /var/cache/zoneminder/cache
  chmod -R 777 /var/cache/zoneminder/cache
else
  echo "Using existing data directory for cache"

  # Check the ownership on the /var/cache/zoneminder/cache directory
  if [ $(stat -c '%U:%G' /var/cache/zoneminder/cache) != 'root:www-data' ]; then
    echo "Correcting /var/cache/zoneminder/cache ownership..."
    chown -R root:www-data /var/cache/zoneminder/cache
  fi

  # Check the permissions on the /var/cache/zoneminder/cache directory
  if [ $(stat -c '%a' /var/cache/zoneminder/cache) != '777' ]; then
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

# Fix memory issue
echo "Setting shared memory to : $SHMEM of $(awk '/MemTotal/ {print $2}' /proc/meminfo) bytes"
umount /dev/shm
mount -t tmpfs -o rw,nosuid,nodev,noexec,relatime,size=${SHMEM} tmpfs /dev/shm

# Install hook packages, if enabled

if [ "$INSTALL_HOOK" == "1" ]; then
  echo "Installing machine learning modules & hooks..."

  # If hook folder exists, copy files into image
  if [ ! -d /config/hook ]; then
    echo "Creating hook folder in config folder"
    mkdir /config/hook
  fi

  # hook helpers are only needed if hooks are enabled
  if [ -d /root/zmeventnotification/zmes_hook_helpers ]; then
    # Python modules needed for hook processing
    apt-get -y install python3-pip cmake
    # pip3 will take care on installing dependent packages
    pip3 install future
    pip3 install /root/zmeventnotification
    rm -rf /root/zmeventnotification/zmes_hook_helpers
  else
    echo "hook python modules are already installed"
  fi

  # Download models files
  if [ "$INSTALL_TINY_YOLO" == "1" ]; then
    if [ ! -d /config/hook/models/tinyyolo ]; then
      echo "Downloading tiny yolo models and configurations..."
      mkdir -p /config/hook/models/tinyyolo
      wget https://pjreddie.com/media/files/yolov3-tiny.weights -O /config/hook/models/tinyyolo/yolov3-tiny.weights
      wget https://raw.githubusercontent.com/pjreddie/darknet/master/cfg/yolov3-tiny.cfg -O /config/hook/models/tinyyolo/yolov3-tiny.cfg
      wget https://raw.githubusercontent.com/pjreddie/darknet/master/data/coco.names -O /config/hook/models/tinyyolo/yolov3-tiny.txt
    else
      echo "Tiny yolo files have already been downloading, skipping..."
    fi
  fi

  if [ "$INSTALL_YOLO" == "1" ]; then
    if [ ! -d /config/hook/models/yolov3 ]; then
      echo "Downloading yolo models and configurations..."
      mkdir -p /config/hook/models/yolov3
      wget https://raw.githubusercontent.com/pjreddie/darknet/master/cfg/yolov3.cfg -O /config/hook/models/yolov3/yolov3.cfg
      wget https://raw.githubusercontent.com/pjreddie/darknet/master/data/coco.names -O /config/hook/models/yolov3/yolov3_classes.txt
      wget https://pjreddie.com/media/files/yolov3.weights -O /config/hook/models/yolov3/yolov3.weights
    else
      echo "Yolo files have already been downloading, skipping..."
    fi
  fi

  # Handle the objectconfig.ini file
  if [ -f /root/objectconfig.ini ]; then
    echo "Moving objectconfig.ini"
    cp /root/objectconfig.ini /config/hook/objectconfig.ini.default
    if [ ! -f /config/hook/objectconfig.ini ]; then
      mv /root/objectconfig.ini /config/hook/objectconfig.ini
    else
      rm -rf /root/objectconfig.ini
    fi
  else
    echo "File objectconfig.ini already moved"
  fi

  # Handle the detect_wrapper.sh file
  if [ -f /root/detect_wrapper.sh ]; then
    echo "Moving detect_wrapper.sh"
    mv /root/detect_wrapper.sh /config/hook/detect_wrapper.sh
  else
    echo "File detect_wrapper.sh already moved"
  fi

  # Handle the detect.py file
  if [ -f /root/detect.py ]; then
    echo "Moving detect.py"
    mv /root/detect.py /config/hook/detect.py
  else
    echo "File detect.py already moved"
  fi

  # Symbolic link for models in /config
  rm -rf /var/lib/zmeventnotification/models
  ln -sf /config/hook/models /var/lib/zmeventnotification/models
  chown -R www-data:www-data /var/lib/zmeventnotification/models

  # Symbolic link for known_faces in /config
  rm -rf /var/lib/zmeventnotification/known_faces
  ln -sf /config/hook/known_faces /var/lib/zmeventnotification/known_faces
  chown -R www-data:www-data /var/lib/zmeventnotification/known_faces

  # Symbolic link for hook files in /config
  ln -sf /config/hook/detect.py /usr/bin/detect.py 2>/dev/null
  ln -sf /config/hook/detect_wrapper.sh /usr/bin/detect_wrapper.sh 2>/dev/null
  chmod +x /usr/bin/detect* 2>/dev/null
  ln -sf /config/hook/objectconfig.ini /etc/zm/ 2>/dev/null

  if [ "$INSTALL_FACE" == "1" ]; then
    # Create known_faces folder if it doesn't exist
    if [ ! -d /config/hook/known_faces ]; then
      echo "Creating hook/known_faces folder in config folder"
      mkdir -p /config/hook/known_faces
    fi
    # Install for face recognition
    apt-get -y install libopenblas-dev liblapack-dev libblas-dev
    pip3 install face_recognition
  fi

  echo "Hook installation process completed"
fi

echo "Starting services..."
service mysql start

# Update the database if necessary
zmupdate.pl -nointeractive
zmupdate.pl -f

service apache2 start
service zoneminder start
