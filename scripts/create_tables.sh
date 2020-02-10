#!/bin/sh

dbhost=localhost

# suppression d'abord
psql -h $dbhost -U redadeg -d redadeg < drop_tables.sql

# création
psql -h $dbhost -U redadeg -d redadeg < create_tables.sql

