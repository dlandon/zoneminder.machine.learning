#!/bin/bash
#
./config_upgrade.py -c /config/hook/objectconfig.ini
if [ -f migrated-objectconfig.ini ]; then
	mv migrated-objectconfig.ini /config/hook/objectconfig.ini
fi
