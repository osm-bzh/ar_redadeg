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
echo "  Création de la base de données $redadegDBName"
echo ""
echo ""
echo "  /!\ Le compte $redadegDBUser doit être SUPERUSER pour exécuter ce script"
echo "  /!\ La base de données $redadegDBName va être supprimée !!"
echo ""
read -p "  Appuyer sur la touche [Entrée] pour continuer sinon faire ctrl + C pour arrêter."
echo ""

# suppression de la base de donnée existante
# on stoppe si impossible genre des connectiosn en cours
PGPASSWORD=$redadegDBPassword $PSQL -h $redadegDBHost -p $redadegDBPort -d postgres -U $redadegDBUser -c "DROP DATABASE IF EXISTS $redadegDBName ;"

# create database with owner redadeg
PGPASSWORD=$redadegDBPassword $PSQL -h $redadegDBHost -p $redadegDBPort -d postgres -U $redadegDBUser -c "CREATE DATABASE $redadegDBName WITH OWNER = $redadegDBUser ENCODING = 'UTF8';" || true

# extensions postgis
PGPASSWORD=$redadegDBPassword $PSQL -h $redadegDBHost -p $redadegDBPort -d $redadegDBName -U $redadegDBUser -c "CREATE EXTENSION postgis;" || true
PGPASSWORD=$redadegDBPassword $PSQL -h $redadegDBHost -p $redadegDBPort -d $redadegDBName -U $redadegDBUser -c "CREATE EXTENSION postgis_topology;" || true
PGPASSWORD=$redadegDBPassword $PSQL -h $redadegDBHost -p $redadegDBPort -d $redadegDBName -U $redadegDBUser -c "CREATE EXTENSION pgrouting;" || true

# permissions
PGPASSWORD=$redadegDBPassword $PSQL -h $redadegDBHost -p $redadegDBPort -d $redadegDBName -U $redadegDBUser -c "ALTER SCHEMA public OWNER TO $redadegDBUser;" || true
PGPASSWORD=$redadegDBPassword $PSQL -h $redadegDBHost -p $redadegDBPort -d $redadegDBName -U $redadegDBUser -c "ALTER TABLE topology.layer OWNER TO $redadegDBUser ;" || true
PGPASSWORD=$redadegDBPassword $PSQL -h $redadegDBHost -p $redadegDBPort -d $redadegDBName -U $redadegDBUser -c "ALTER TABLE topology.topology OWNER TO $redadegDBUser ;" || true

# vérifications
PGPASSWORD=$redadegDBPassword $PSQL -h $redadegDBHost -p $redadegDBPort -d $redadegDBName -U $redadegDBUser -c "SELECT * FROM postgis_version();"
PGPASSWORD=$redadegDBPassword $PSQL -h $redadegDBHost -p $redadegDBPort -d $redadegDBName -U $redadegDBUser -c "SELECT * FROM pgr_version();"


echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  F I N"
echo ""
