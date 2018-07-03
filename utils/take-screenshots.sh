#!/bin/sh

set -e

./utils/ansi-screenshots/ansi_screenshot.sh
scrot "$1"
