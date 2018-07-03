#!/bin/sh

set -e

# The sikuli-ide packaged with ubuntu 16.04 does not seem to work correctly: missing dependencies, some dependencies are too recent, …
mkdir ~/sikulix/
wget https://launchpadlibrarian.net/359997648/sikulixsetup-1.1.2.jar -O ~/sikulix/sikulixsetup-1.1.2.jar
(cd ~/sikulix && java -jar sikulixsetup-1.1.2.jar options 1 1.1)
echo 'export PATH="$HOME/sikulix/:$PATH"'
