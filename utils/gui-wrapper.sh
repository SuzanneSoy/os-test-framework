#!/bin/sh
xvfb-run -a sh -c 'fluxbox 2>/dev/null & sleep 3; "$@"' utils/gui-wrapper.sh-subshell "$@"