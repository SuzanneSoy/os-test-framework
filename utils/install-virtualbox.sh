#!/bin/sh

set -e

echo "deb https://download.virtualbox.org/virtualbox/debian $(lsb_release --short --codename) contrib" \
    | sudo tee /etc/apt/sources.list.d/virtualbox.list
sudo apt-get update
sudo apt-get -y install virtualbox "linux-headers-$(uname -r)"
