#!/bin/bash
#
# 40_gen_ssl_keys.sh
#

if [[ -f /config/keys/cert.key && -f /config/keys/cert.crt ]]; then
	echo "using existing keys in \"/config/keys\""
else
	echo "generating self-signed keys in /config/keys, you can replace these with your own keys if required"
	mkdir -p config/keys
	openssl req -x509 -nodes -days 4096 -newkey rsa:2048 -out /config/keys/cert.crt -keyout /config/keys/cert.key -subj "/C=US/ST=NY/L=New York/O=Zoneminder/OU=Zoneminder/CN=*"
fi

chown root:root /config/keys
chmod 777 /config/keys
