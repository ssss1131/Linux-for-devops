#!/bin/bash
TS=$(date +%Y%m%d_%H%M%S)
sudo -u postgres pg_dump nc_ttp | gzip > /var/backups/nc-ttp/db/nc_ttp_$TS.sql.gz
find /var/backups/nc-ttp/db -name '*.sql.gz' -mtime +7 -delete
