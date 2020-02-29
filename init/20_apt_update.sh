#!/bin/sh
#
# 20_apt_update.sh
#

# Update repositories
echo "Performing updates..."
apt-get update 2>&1 | tee /tmp/test_update

# Verify that the updates will work.
if [ "`cat /tmp/test_update | grep 'Failed'`" = "" ]; then
	# Perform Upgrade
	apt-get -y upgrade -o Dpkg::Options::="--force-confold"

	# Clean + purge old/obsoleted packages
	apt-get -y autoremove
else
	echo "Warning: Unable to update!  Check Internet connection."
fi
