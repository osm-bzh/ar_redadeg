#!/bin/bash

# exit dès que qqch se passe mal
#set -e
# ?
set -u

# utiliser un compte SUPERUSER pour exécuter ce script

# argument 1 = millesime redadeg
millesime=$1

PSQL=/usr/bin/psql
DB_HOST=localhost
DB_NAME=redadeg_$millesime



echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Création de la base de données $DB_NAME"
echo ""
echo ""


echo "La base de données $DB_NAME va être supprimée !!"

if [ ! -t 0 ]; then x-terminal-emulator -e "$0"; exit 0; fi
read -r -p "Appuyer sur n'importe quelle touche pour continuer..." key

# suppression de la base de données existantes
echo "DROP DATABASE $DB_NAME ;" | psql -U postgres -w

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

