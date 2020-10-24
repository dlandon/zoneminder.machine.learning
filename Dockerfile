FROM phusion/baseimage:bionic-1.0.0 as builder

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
	ZM_VERS="1.34" \
	SHMEM="50%" \
	PUID="99" \
	PGID="100"

FROM builder as build1
COPY init/ /etc/my_init.d/
COPY defaults/ /root/

RUN	add-apt-repository -y ppa:iconnor/zoneminder-$ZM_VERS && \
	add-apt-repository ppa:ondrej/php && \
	apt-get update && \
	apt-get -y upgrade -o Dpkg::Options::="--force-confold" && \
	apt-get -y dist-upgrade -o Dpkg::Options::="--force-confold" && \
	apt-get -y install apache2 mariadb-server && \
	apt-get -y install ssmtp mailutils net-tools wget sudo make && \
	apt-get -y install php$PHP_VERS php$PHP_VERS-fpm libapache2-mod-php$PHP_VERS php$PHP_VERS-mysql php$PHP_VERS-gd && \
	apt-get -y install libcrypt-mysql-perl libyaml-perl libjson-perl libavutil-dev && \
	apt-get -y install --no-install-recommends libvlc-dev libvlccore-dev vlc && \
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
	perl -MCPAN -e "force install Net::MQTT::Simple::Auth"

FROM build2 as build3
RUN	cd /root && \
	chown -R www-data:www-data /usr/share/zoneminder/ && \
	echo "ServerName localhost" >> /etc/apache2/apache2.conf && \
	sed -i "s|^;date.timezone =.*|date.timezone = ${TZ}|" /etc/php/$PHP_VERS/apache2/php.ini && \
	service mysql start && \
	mysql -uroot < /usr/share/zoneminder/db/zm_create.sql && \
	mysql -uroot -e "grant all on zm.* to 'zmuser'@localhost identified by 'zmpass';" && \
	mysqladmin -uroot reload && \
	mysql -sfu root < "mysql_secure_installation.sql" && \
	rm mysql_secure_installation.sql && \
	mysql -sfu root < "mysql_defaults.sql" && \
	rm mysql_defaults.sql

FROM build3 as build4
RUN	mv /root/zoneminder /etc/init.d/zoneminder && \
	chmod +x /etc/init.d/zoneminder && \
	service mysql restart && \
	sleep 5 && \
	service apache2 restart && \
	service zoneminder start

FROM build4 as build5
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
	cp /etc/apache2/sites-enabled/default-ssl.conf /etc/apache2/sites-enabled/default-ssl.conf.default

FROM build5 as build6
RUN	apt-get -y remove make && \
	apt-get -y clean && \
	apt-get -y autoremove && \
	rm -rf /tmp/* /var/tmp/* && \
	chmod +x /etc/my_init.d/*.sh

FROM build6 as build7
VOLUME \
	["/config"] \
	["/var/cache/zoneminder"]

FROM build7 as build8
EXPOSE 80 443 9000

FROM build8
CMD ["/sbin/my_init"]
