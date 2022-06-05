#!/bin/bash

chmod ugo+w /var/logs/archive
tar -C "/var/logs/archive" -xf /var/logs/archive/backup.tar.gz
find /var/logs/archive -type f -name "*.tmp" -exec rm -f {} \;
grep -lr "user deleted" /var/logs/archive