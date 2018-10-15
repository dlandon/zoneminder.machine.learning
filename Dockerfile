FROM dlandon/baseimage

LABEL maintainer="dlandon"

ENV	PHP_VERS="7.1"
ENV	ZM_VERS="1.32"
ENV	ZMEVENT_VERS="2.0"

ENV	SHMEM="50%" \
	PUID="99" \
	PGID="100"

COPY init/ /etc/my_init.d/
COPY defaults/ /root/
COPY zmeventnotification/zmeventnotification.pl /usr/bin/
COPY zmeventnotification/zmeventnotification.ini /root/

RUN	echo "deb http://ppa.launchpad.net/ondrej/php/ubuntu xenial main" >> /etc/apt/sources.list.d/php7.list && \
	echo "deb-src http://ppa.launchpad.net/ondrej/php/ubuntu xenial main" >> /etc/apt/sources.list.d/php7.list && \
	apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 4F4EA0AAE5267A6C

RUN	add-apt-repository -y ppa:iconnor/zoneminder-$ZM_VERS && \
	add-apt-repository ppa:ondrej/php && \
	apt-get update && \
	apt-get -y upgrade -o Dpkg::Options::="--force-confold" && \
	apt-get -y dist-upgrade && \
	apt-get -y install php$PHP_VERS mariadb-server && \
	apt-get -y install wget sudo make && \
	apt-get -y install libav-tools && \
	apt-get -y install apache2 ssmtp mailutils net-tools && \
	apt-get -y install php$PHP_VERS-curl php$PHP_VERS-fpm php$PHP_VERS-gd php$PHP_VERS-gmp php$PHP_VERS-imap php$PHP_VERS-intl php$PHP_VERS-ldap && \
	apt-get -y install php$PHP_VERS-mysql php$PHP_VERS-mbstring php$PHP_VERS-xml php$PHP_VERS-xmlrpc php$PHP_VERS-zip php$PHP_VERS-apcu && \
	apt-get -y install zoneminder

RUN	rm /etc/mysql/my.cnf && \
	cp /etc/mysql/mariadb.conf.d/50-server.cnf /etc/mysql/my.cnf && \
	adduser www-data video && \
	a2enmod php$PHP_VERS && \
	a2enconf php$PHP_VERS-fpm && \
	a2enmod cgi && \
	a2enmod ssl && \
	a2enmod rewrite && \
	a2enmod expires && \
	a2enmod headers && \
	a2enconf zoneminder && \
	echo "extension=apcu.so" > /etc/php/$PHP_VERS/mods-available/apcu.ini && \
	echo "extension=mcrypt.so" > /etc/php/$PHP_VERS/mods-available/mcrypt.ini && \
	perl -MCPAN -e "force install Net::WebSocket::Server" && \
	perl -MCPAN -e "force install LWP::Protocol::https" && \
	perl -MCPAN -e "force install Config::IniFiles" && \
	perl -MCPAN -e "force install Net::MQTT::Simple"

RUN	cd /root && \
	wget www.andywilcock.com/code/cambozola/cambozola-latest.tar.gz && \
	tar xvf cambozola-latest.tar.gz && \
	cp cambozola*/dist/cambozola.jar /usr/share/zoneminder/www && \
	rm -rf cambozola*/ && \
	rm -rf cambozola-latest.tar.gz && \
	chmod 775 /usr/share/zoneminder/www/cambozola.jar && \
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

RUN	mv /root/zoneminder /etc/init.d/zoneminder && \
	chmod +x /etc/init.d/zoneminder && \
	service mysql restart && \
	sleep 10 && \
	service apache2 restart && \
	service zoneminder start

RUN	systemd-tmpfiles --create zoneminder.conf && \
	mv /root/default-ssl.conf /etc/apache2/sites-enabled/default-ssl.conf && \
	mkdir /etc/apache2/ssl/ && \
	chmod a+x /usr/bin/zmeventnotification.pl && \
	mkdir /etc/private && \
	chmod 777 /etc/private && \
	chmod -R +x /etc/my_init.d/ && \
	cp -p /etc/zm/zm.conf /root/zm.conf

RUN	apt-get -y remove wget make && \
	apt-get -y clean && \
	apt-get -y autoremove && \
	rm -rf /tmp/* /var/tmp/*

VOLUME \
	["/config"] \
	["/var/cache/zoneminder"]

EXPOSE 80 443 9000
