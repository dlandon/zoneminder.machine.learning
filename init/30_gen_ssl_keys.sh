#!/bin/bash
#
# 30_gen_ssl_keys.sh
#

if [[ -f /config/keys/cert.key && -f /config/keys/cert.crt ]]; then
	echo "using existing keys in \"/config/keys\""
	if [[ ! -f /config/keys/ServerName ]]; then
		echo "localhost" > /config/keys/ServerName
	fi
	SERVER=`cat /config/keys/ServerName`
	sed -i "/ServerName/c\ServerName $SERVER" /etc/apache2/apache2.conf
else
	echo "generating self-signed keys in /config/keys, you can replace these with your own keys if required"
	mkdir -p /config/keys
	echo "localhost" >> /config/keys/ServerName
	openssl req -x509 -nodes -days 4096 -newkey rsa:2048 -out /config/keys/cert.crt -keyout /config/keys/cert.key -subj "/C=US/ST=NY/L=New York/O=Zoneminder/OU=Zoneminder/CN=localhost"
fi

chown root:root /config/keys
chmod 777 /config/keys
