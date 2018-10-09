#!/bin/bash
#
# 06_set_php_time.sh
#

sed -i "s|^date.timezone =.*$|date.timezone = ${TZ}|" /etc/php/$PHP_VERS/apache2/php.ini
