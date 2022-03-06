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



echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Export des données phase 3 pour le millésime $millesime"
echo ""

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo ""
echo "  Exports GeoJSON pour umap"

rm -f $rep_data/phase_3_pk.geojson
ogr2ogr -f "GeoJSON" $rep_data/phase_3_pk.geojson PG:"host=$DB_HOST port=$DB_PORT user=$DB_USER password=$DB_PASSWD dbname=$DB_NAME" phase_3_pk_4326

echo "  fait"

