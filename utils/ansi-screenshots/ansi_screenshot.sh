#!/bin/sh

set -e

import -window root png:- | "$(dirname "$0")/to_ansi.sh" png:- 128
