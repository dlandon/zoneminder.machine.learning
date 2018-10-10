FROM dlandon/baseimage

LABEL maintainer="dlandon"

ENV	PHP_VERS="7.1"
ENV	SHMEM="50%" \
	PUID="99" \
	PGID="100"

COPY init/ /etc/my_init.d/
COPY defaults/ /root/
COPY zmeventnotification/zmeventnotification.pl /usr/bin/
COPY zmeventnotification/zmeventnotification.ini /root/

RUN add-apt-repository -y ppa:iconnor/zoneminder-1.32 && \
	add-apt-repository ppa:ondrej/php && \
	apt-get update && \
	apt-get -y upgrade -o Dpkg::Options::="--force-confold" && \
	apt-get -y dist-upgrade && \
	apt-get -y install php$PHP_VERS mariadb-server && \
	apt-get -y install wget sudo && \
	apt-get -y install cakephp && \
	apt-get -y install libav-tools && \
	apt-get -y install apache2 ssmtp mailutils net-tools && \
	apt-get -y install php$PHP_VERS-common php$PHP_VERS-curl php$PHP_VERS-fpm php$PHP_VERS-gd php$PHP_VERS-gmp php$PHP_VERS-imap php$PHP_VERS-intl php$PHP_VERS-ldap && \
	apt-get -y install php$PHP_VERS-mbstring php$PHP_VERS-mcrypt php$PHP_VERS-mysql php$PHP_VERS-opcache php$PHP_VERS-xml php$PHP_VERS-xmlrpc php$PHP_VERS-zip php$PHP_VERS-apcu && \
	apt-get -y install zoneminder && \
	apt-get -y install libcrypt-mysql-perl libyaml-perl make libjson-perl

RUN	echo "extension=apcu.so" > /etc/php/$PHP_VERS/mods-available/apcu.ini && \
	rm /etc/mysql/my.cnf && \
	cp /etc/mysql/mariadb.conf.d/50-server.cnf /etc/mysql/my.cnf && \
	adduser www-data video && \
	a2enmod cgi && \
	a2enmod ssl && \
	a2enmod php$PHP_VERS && \
	a2enconf zoneminder && \
	a2enmod rewrite && \
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
	/etc/init.d/zoneminder start

RUN	systemd-tmpfiles --create zoneminder.conf && \
	mv /root/default-ssl.conf /etc/apache2/sites-enabled/default-ssl.conf && \
	mkdir /etc/apache2/ssl/ && \
	chmod a+x /usr/bin/zmeventnotification.pl && \
	mkdir /etc/private && \
	chmod 777 /etc/private && \
	chmod -R +x /etc/my_init.d/ && \
	cp -p /etc/zm/zm.conf /root/zm.conf

RUN	apt-get -y remove wget make && \
	update-rc.d -f zoneminder remove && \
	update-rc.d -f mysql remove && \
	update-rc.d -f mysql-common remove && \
	apt-get -y clean && \
	apt-get -y autoremove && \
	rm -rf /tmp/* /var/tmp/*

VOLUME \
	["/config"] \
	["/var/cache/zoneminder"]

EXPOSE 80 443 9000
