#!/bin/sh

set -e

# The sikuli-ide packaged with ubuntu 16.04 does not seem to work correctly: missing dependencies, some dependencies are too recent, …
mkdir ~/sikulix/
curl -o ~/sikulix/sikulixsetup-1.1.3.jar https://launchpad.net/sikuli/sikulix/1.1.3/+download/sikulixsetup-1.1.3.jar
(cd ~/sikulix && java -jar sikulixsetup-1.1.3.jar options 1 1.1) || (cat ~/sikulix/SikuliX-1.1.3-SetupLog.txt; exit 1)
echo 'export PATH="$HOME/sikulix/:$PATH"'
