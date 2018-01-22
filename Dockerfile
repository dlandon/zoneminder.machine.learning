FROM dlandon/baseimage

LABEL maintainer="dlandon"

ENV SHMEM="50%"

COPY init/ /etc/my_init.d/
COPY defaults/ /root/

RUN add-apt-repository -y ppa:iconnor/zoneminder && \
	apt-get update && \
	apt-get upgrade -y -o Dpkg::Options::="--force-confold" && \
	apt-get dist-upgrade -y && \
	apt-get install -y mariadb-server

RUN	rm /etc/mysql/my.cnf && \
	cp /etc/mysql/mariadb.conf.d/50-server.cnf /etc/mysql/my.cnf

RUN	apt-get install -y wget && \
	apt-get install -y sudo && \
	apt-get install -y cakephp && \
	apt-get install -y libav-tools && \
	apt-get install -y ssmtp mailutils php-curl net-tools && \
	apt-get install -y zoneminder=1.30.4* php-gd && \
	chmod 740 /etc/zm/zm.conf && \
	chown root:www-data /etc/zm/zm.conf && \
	adduser www-data video && \
	a2enmod cgi && \
	a2enconf zoneminder && \
	a2enmod rewrite

RUN	cd /root && \
	wget www.andywilcock.com/code/cambozola/cambozola-latest.tar.gz && \
	tar xvf cambozola-latest.tar.gz && \
	cp cambozola*/dist/cambozola.jar /usr/share/zoneminder/www && \
	rm -rf cambozola*/ && \
	rm -rf cambozola-latest.tar.gz && \
	chmod 775 /usr/share/zoneminder/www/cambozola.jar && \
	chown -R www-data:www-data /usr/share/zoneminder/

RUN	echo "ServerName localhost" >> /etc/apache2/apache2.conf

RUN	sed -i "s|^;date.timezone =.*|date.timezone = ${TZ}|" /etc/php/7.0/apache2/php.ini && \
	sed -i "s|^start() {$|start() {\n        sleep 15|" /etc/init.d/zoneminder

RUN	cd /root && \
	service mysql start && \
	mysql -uroot < /usr/share/zoneminder/db/zm_create.sql && \
	mysql -uroot -e "grant all on zm.* to 'zmuser'@localhost identified by 'zmpass';" && \
	mysqladmin -uroot reload && \
	mysql -sfu root < "mysql_secure_installation.sql" && \
	rm mysql_secure_installation.sql && \
	mysql -sfu root < "mysql_defaults.sql" && \
	rm mysql_defaults.sql

RUN	service mysql restart && \
	sleep 10 && \
	service apache2 restart && \
	service zoneminder start && \
	apt-get clean

RUN	systemd-tmpfiles --create zoneminder.conf && \
	chmod -R +x /etc/my_init.d/ && \
	cp -p /etc/zm/zm.conf /root/zm.conf

RUN	rm /etc/apt/sources.list.d/iconnor-ubuntu-zoneminder-xenial.list && \
	apt-get -y remove wget && \
	update-rc.d -f zoneminder remove && \
	update-rc.d -f mysql remove && \
	update-rc.d -f mysql-common remove && \
	apt-get clean -y && \
	apt-get -y autoremove

VOLUME \
	["/config"] \
	["/var/cache/zoneminder"]

EXPOSE 80
