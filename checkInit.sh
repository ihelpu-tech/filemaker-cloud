#!/usr/bin/env bash

# Test to see which init system is running
# https://unix.stackexchange.com/questions/18209/detect-init-system-using-the-shell
if [[ `/sbin/init --version` =~ upstart ]]; then echo using upstart;
elif [[ `systemctl` =~ -\.mount ]]; then echo using systemd;
elif [[ -f /etc/init.d/cron && ! -h /etc/init.d/cron ]]; then echo using sysv-init;
else echo cannot tell; fi