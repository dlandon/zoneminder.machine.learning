FROM phusion/baseimage:master as builder

LABEL maintainer="dlandon"

ENV	DEBCONF_NONINTERACTIVE_SEEN="true" \
	DEBIAN_FRONTEND="noninteractive" \
	DISABLE_SSH="true" \
	HOME="/root" \
	LC_ALL="C.UTF-8" \
	LANG="en_US.UTF-8" \
	LANGUAGE="en_US.UTF-8" \
	TZ="Etc/UTC" \
	TERM="xterm" \
	PHP_VERS="7.4" \
	ZM_VERS="1.36" \
	OPENCV_VERS="4.5.3" \
	PUID="99" \
	PGID="100"

FROM builder as build1
COPY init/ /etc/my_init.d/
COPY defaults/ /root/
COPY zmeventnotification/ /root/zmeventnotification/

RUN	add-apt-repository -y ppa:iconnor/zoneminder-$ZM_VERS && \
	add-apt-repository ppa:ondrej/php && \
	add-apt-repository ppa:ondrej/apache2 && \
	apt-get update && \
	apt-get -y upgrade -o Dpkg::Options::="--force-confold" && \
	apt-get -y dist-upgrade -o Dpkg::Options::="--force-confold" && \
	apt-get -y install apache2 mariadb-server && \
	apt-get -y install ssmtp mailutils net-tools wget sudo make cmake gcc && \
	apt-get -y install php$PHP_VERS php$PHP_VERS-fpm libapache2-mod-php$PHP_VERS php$PHP_VERS-mysql php$PHP_VERS-gd && \
	apt-get -y install libcrypt-mysql-perl libyaml-perl libjson-perl libavutil-dev ffmpeg && \
	apt-get -y install --no-install-recommends libvlc-dev libvlccore-dev vlc-bin vlc-plugin-base vlc-plugin-video-output && \
	apt-get -y install zoneminder
	
FROM build1 as build2
RUN	rm /etc/mysql/my.cnf && \
	cp /etc/mysql/mariadb.conf.d/50-server.cnf /etc/mysql/my.cnf && \
	adduser www-data video && \
	a2enmod php$PHP_VERS proxy_fcgi ssl rewrite expires headers && \
	a2enconf php$PHP_VERS-fpm zoneminder && \
	echo "extension=apcu.so" > /etc/php/$PHP_VERS/mods-available/apcu.ini && \
	echo "extension=mcrypt.so" > /etc/php/$PHP_VERS/mods-available/mcrypt.ini && \
	perl -MCPAN -e "force install Net::WebSocket::Server" && \
	perl -MCPAN -e "force install LWP::Protocol::https" && \
	perl -MCPAN -e "force install Config::IniFiles" && \
	perl -MCPAN -e "force install Net::MQTT::Simple" && \
	perl -MCPAN -e "force install Net::MQTT::Simple::Auth" && \
	perl -MCPAN -e "force install Time::Piece"

FROM build2 as build3
RUN	apt-get -y install python3-pip && \
	apt-get -y install libopenblas-dev liblapack-dev libblas-dev && \
	pip3 install future && \
	pip3 install /root/zmeventnotification && \
	pip3 install face_recognition && \
	rm -r /root/zmeventnotification/zmes_hook_helpers && \
	cd /root/ && \
	mkdir -p models/tinyyolov3 && \
	wget https://pjreddie.com/media/files/yolov3-tiny.weights -O models/tinyyolov3/yolov3-tiny.weights && \
	wget https://raw.githubusercontent.com/pjreddie/darknet/master/cfg/yolov3-tiny.cfg -O models/tinyyolov3/yolov3-tiny.cfg && \
	wget https://raw.githubusercontent.com/pjreddie/darknet/master/data/coco.names -O models/tinyyolov3/coco.names && \
	mkdir -p models/yolov3 && \
	wget https://raw.githubusercontent.com/pjreddie/darknet/master/cfg/yolov3.cfg -O models/yolov3/yolov3.cfg && \
	wget https://raw.githubusercontent.com/pjreddie/darknet/master/data/coco.names -O models/yolov3/coco.names && \
	wget https://pjreddie.com/media/files/yolov3.weights -O models/yolov3/yolov3.weights && \
	mkdir -p models/tinyyolov4 && \
	wget https://github.com/AlexeyAB/darknet/releases/download/darknet_yolo_v4_pre/yolov4-tiny.weights -O models/tinyyolov4/yolov4-tiny.weights && \
	wget https://raw.githubusercontent.com/AlexeyAB/darknet/master/cfg/yolov4-tiny.cfg -O models/tinyyolov4/yolov4-tiny.cfg && \
	wget https://raw.githubusercontent.com/pjreddie/darknet/master/data/coco.names -O models/tinyyolov4/coco.names && \
	mkdir -p models/yolov4 && \
	wget https://raw.githubusercontent.com/AlexeyAB/darknet/master/cfg/yolov4.cfg -O models/yolov4/yolov4.cfg && \
	wget https://raw.githubusercontent.com/pjreddie/darknet/master/data/coco.names -O models/yolov4/coco.names && \
	wget https://github.com/AlexeyAB/darknet/releases/download/darknet_yolo_v3_optimal/yolov4.weights -O models/yolov4/yolov4.weights

FROM build3 as build4
RUN	cd /root && \
	chown -R www-data:www-data /usr/share/zoneminder/ && \
	echo "ServerName localhost" >> /etc/apache2/apache2.conf && \
	sed -i "s|^;date.timezone =.*|date.timezone = ${TZ}|" /etc/php/$PHP_VERS/apache2/php.ini && \
	service mysql start && \
	mysql -uroot -e "grant all on zm.* to 'zmuser'@localhost identified by 'zmpass';" && \
	mysqladmin -uroot reload && \
	mysql -sfu root < "mysql_secure_installation.sql" && \
	rm mysql_secure_installation.sql && \
	mysql -sfu root < "mysql_defaults.sql" && \
	rm mysql_defaults.sql

FROM build4 as build5
RUN	mv /root/zoneminder /etc/init.d/zoneminder && \
	chmod +x /etc/init.d/zoneminder && \
	service mysql restart && \
	sleep 5 && \
	service apache2 start && \
	service zoneminder start

FROM build5 as build6
RUN	systemd-tmpfiles --create zoneminder.conf && \
	mv /root/default-ssl.conf /etc/apache2/sites-enabled/default-ssl.conf && \
	mkdir /etc/apache2/ssl/ && \
	mkdir -p /var/lib/zmeventnotification/images && \
	chown -R www-data:www-data /var/lib/zmeventnotification/ && \
	chmod -R +x /etc/my_init.d/ && \
	cp -p /etc/zm/zm.conf /root/zm.conf && \
	echo "#!/bin/sh\n\n/usr/bin/zmaudit.pl -f" >> /etc/cron.weekly/zmaudit && \
	chmod +x /etc/cron.weekly/zmaudit && \
	cp /etc/apache2/ports.conf /etc/apache2/ports.conf.default && \
	cp /etc/apache2/sites-enabled/default-ssl.conf /etc/apache2/sites-enabled/default-ssl.conf.default && \
	sed -i s#3.13#3.25#g /etc/syslog-ng/syslog-ng.conf && \
	sed -i 's#use_dns(no)#use_dns(yes)#' /etc/syslog-ng/syslog-ng.conf

FROM build6 as build7
RUN	cd /root && \
	wget -q -O opencv.zip https://github.com/opencv/opencv/archive/$OPENCV_VERS.zip && \
	wget -q -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/$OPENCV_VERS.zip && \
	unzip opencv.zip && \
	unzip opencv_contrib.zip && \
	mv $(ls -d opencv-*) opencv && \
	mv opencv_contrib-$OPENCV_VERS opencv_contrib && \
	rm *.zip && \
	cd /root/opencv && \
	mkdir build && \
	cd build && \
	cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=/usr/local -D INSTALL_PYTHON_EXAMPLES=OFF -D INSTALL_C_EXAMPLES=OFF -D OPENCV_ENABLE_NONFREE=ON -D OPENCV_EXTRA_MODULES_PATH=/root/opencv_contrib/modules -D HAVE_opencv_python3=ON -D PYTHON_EXECUTABLE=/usr/bin/python3 -D PYTHON2_EXECUTABLE=/usr/bin/python2 -D BUILD_EXAMPLES=OFF .. >/dev/null && \
	make -j4 && \
	make install && \
	cd /root && \
	rm -r opencv*

FROM build7 as build8
RUN	apt-get -y clean && \
	apt-get -y autoremove && \
	rm -rf /tmp/* /var/tmp/* && \
	chmod +x /etc/my_init.d/*.sh

FROM build8 as build9
VOLUME \
	["/config"] \
	["/var/cache/zoneminder"]

FROM build9 as build10
EXPOSE 80 443 9000

FROM build10
CMD ["/sbin/my_init"]
