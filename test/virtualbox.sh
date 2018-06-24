#!/bin/sh
set -e

ls /usr/bin | grep -i virtualbox || true
ls /usr/bin | grep -i vboxmanage || true
virtualbox --help
VBoxManage --help