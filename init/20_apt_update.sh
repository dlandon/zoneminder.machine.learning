#!/bin/sh
#
# 20_apt_update.sh
#

# Update repositories
apt-get update

# Perform Upgrade
apt-get -y upgrade
apt-get -y dist-upgrade

# Clean + purge old/obsoleted packages
apt-get -y autoremove
