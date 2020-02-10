#!/bin/sh


# utiliser un compte SUPERUSER pour exécuter ce script

dbhost=localhost

#psql -h $dbhost -d postgres -c "DROP DATABASE IF EXISTS redadeg; DROP ROLE IF EXISTS redadeg;"

# create role
psql -h $dbhost -d postgres -c "CREATE USER redadeg WITH PASSWORD 'redadeg' SUPERUSER;"

# create database with owner redadeg
psql -h $dbhost -d postgres -c "CREATE DATABASE redadeg WITH OWNER = redadeg ENCODING = 'UTF8';"

# extensions postgis
psql -h $dbhost -d redadeg -c "CREATE EXTENSION postgis;"
psql -h $dbhost -d redadeg -c "CREATE EXTENSION postgis_topology;"
psql -h $dbhost -d redadeg -c "CREATE EXTENSION pgrouting;"

# permissions
psql -h $dbhost -d redadeg -c "ALTER SCHEMA public OWNER TO redadeg;"
psql -h $dbhost -d redadeg -c "ALTER TABLE topology.layer OWNER TO redadeg ;"
psql -h $dbhost -d redadeg -c "ALTER TABLE topology.topology OWNER TO redadeg ;"

# vérifications
psql -h $dbhost -d redadeg -c "SELECT * FROM postgis_version();"
psql -h $dbhost -d redadeg -c "SELECT * FROM pgr_version();"

