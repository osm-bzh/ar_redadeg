#!/bin/sh


# utiliser un compte SUPERUSER pour exécuter ce script

# create role
createuser -l -S redadeg
# password
psql -d postgres -c "ALTER USER redadeg WITH PASSWORD 'redadeg';"

# create database with owner redadeg
createdb -E UTF8 -O redadeg redadeg

# postgis extension
psql -d redadeg -c "CREATE EXTENSION postgis;" 


# create tables
psql -d redadeg -U redadeg -W < create_tables_3948.sql

