#!/bin/bash
#
# 06_set_php_time.sh
#

sed -i "s|^date.timezone =.*$|date.timezone = ${TZ}|" /etc/php/7.0/apache2/php.ini
