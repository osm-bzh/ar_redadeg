#!/bin/sh


# utiliser un compte SUPERUSER pour exécuter ce script

millesime=2022

PSQL=/usr/bin/psql
DB_HOST=localhost
DB_NAME=redadeg_$millesime

psql -h $DB_HOST -d postgres -c "DROP DATABASE IF EXISTS $DB_NAME; DROP ROLE IF EXISTS redadeg;"

# create role
psql -h $DB_HOST -d postgres -c "CREATE USER redadeg WITH PASSWORD 'redadeg' SUPERUSER;"

# create database with owner redadeg
psql -h $DB_HOST -d postgres -c "CREATE DATABASE $DB_NAME WITH OWNER = redadeg ENCODING = 'UTF8';"

# extensions postgis
psql -h $DB_HOST -d $DB_NAME -c "CREATE EXTENSION postgis;"
psql -h $DB_HOST -d $DB_NAME -c "CREATE EXTENSION postgis_topology;"
psql -h $DB_HOST -d $DB_NAME -c "CREATE EXTENSION pgrouting;"

# permissions
psql -h $DB_HOST -d $DB_NAME -c "ALTER SCHEMA public OWNER TO redadeg;"
psql -h $DB_HOST -d $DB_NAME -c "ALTER TABLE topology.layer OWNER TO redadeg ;"
psql -h $DB_HOST -d $DB_NAME -c "ALTER TABLE topology.topology OWNER TO redadeg ;"

# vérifications
psql -h $DB_HOST -d $DB_NAME -c "SELECT * FROM postgis_version();"
psql -h $DB_HOST -d $DB_NAME -c "SELECT * FROM pgr_version();"

