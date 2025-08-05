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
. ../../scripts_v2/config.sh


echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Création de la couche des communes dans la BD OSM"
echo ""

PGPASSWORD=$osmDBPassword $PSQL -h $osmDBHost -p $osmDBPort -U $osmDBUser -d $osmDBName -f create_osm_municipalities_tables.sql

echo "  fait"
echo ""

echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Remplissage de la couche des communes dans la BD OSM"
echo ""

PGPASSWORD=$osmDBPassword $PSQL -h $osmDBHost -p $osmDBPort -U $osmDBUser -d $osmDBName -f insert_into_municipalities_polygon.sql

echo "  fait"
echo ""

echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Export de la table"
echo ""

PGPASSWORD=$osmDBPassword pg_dump --file "$rep_data/sql/osm_municipalities_polygon.sql" \
  --host "$osmDBHost" --port "$osmDBPort" --username "$osmDBUser" --no-password \
  --format=p --data-only --no-owner --no-privileges \
  --table "public.osm_municipalities_polygon" "$osmDBName"

echo "  fait"
echo ""

echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Vidage de la couche des communes dans la BD redadeg $1"
echo ""

PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c \
"TRUNCATE TABLE osm_municipalities_polygon ;"

PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c \
"VACUUM FULL osm_municipalities_polygon ;"

echo "  fait"
echo ""

echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Chargement de l'export dans la couche des communes dans la BD redadeg $1"
echo ""

PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f "$rep_data/sql/osm_municipalities_polygon.sql"


echo "  fait"
echo ""


echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  F I N "


