#! /bin/bash

# exit dès que qqch se passe mal
set -e
# sortir si "unbound variable"
#set -u

if [ -z "$1" ]
  then
    echo "Pas de millésime en argument --> stop"
    exit 1
fi

# lecture du fichier de configuration
. config.sh



echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Création de la base de données $DB_NAME"
echo ""
echo ""
echo "  /!\ Le compte $DB_USER doit être SUPERUSER pour exécuter ce script"
echo "  /!\ La base de données $DB_NAME va être supprimée !!"
echo ""
read -p "  Appuyer sur la touche [Entrée] pour continuer sinon faire ctrl + C pour arrêter."
echo ""


# create role
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -d postgres -U $DB_USER -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWD' SUPERUSER;" || true

# suppression de la base de donnée existante
# on stoppe si impossible genre des connectiosn en cours
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -d postgres -U $DB_USER -c "DROP DATABASE IF EXISTS $DB_NAME ;"

# create database with owner redadeg
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -d postgres -U $DB_USER -c "CREATE DATABASE $DB_NAME WITH OWNER = $DB_USER ENCODING = 'UTF8';" || true

# extensions postgis
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -d $DB_NAME -U $DB_USER -c "CREATE EXTENSION postgis;" || true
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -d $DB_NAME -U $DB_USER -c "CREATE EXTENSION postgis_topology;" || true
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -d $DB_NAME -U $DB_USER -c "CREATE EXTENSION pgrouting;" || true

# permissions
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -d $DB_NAME -U $DB_USER -c "ALTER SCHEMA public OWNER TO $DB_USER;" || true
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -d $DB_NAME -U $DB_USER -c "ALTER TABLE topology.layer OWNER TO $DB_USER ;" || true
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -d $DB_NAME -U $DB_USER -c "ALTER TABLE topology.topology OWNER TO $DB_USER ;" || true

# vérifications
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -d $DB_NAME -U $DB_USER -c "SELECT * FROM postgis_version();"
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -d $DB_NAME -U $DB_USER -c "SELECT * FROM pgr_version();"


echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  F I N"
echo ""
