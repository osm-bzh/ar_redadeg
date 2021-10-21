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
echo "  Récupération des fichiers geojson depuis umap"
echo ""

# traitement des tracés manuels

# on commence par supprimer la table
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "DROP TABLE IF EXISTS phase_1_trace_3857 CASCADE;"
# PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "DROP TABLE IF EXISTS phase_1_pk_vip_3857;"
echo ""


# on va lire le fichier de config des couches umap pour boucler
IFS="="
while read -r line
do
  layer=$line

  echo "  umap layer id = $layer"
  wget -q -O $rep_data/phase_1_umap_trace_$layer.geojson  https://umap.openstreetmap.fr/fr/datalayer/$layer
  echo "  recup ok"

  # on charge dans postgis
  # note : les coordonnées sont en 3857 mais la déclaration de la table = 4326

  echo "  chargement dans la couche d'import"
  ogr2ogr -f "PostgreSQL" PG:"host=$DB_HOST port=$DB_PORT user=$DB_USER password=$DB_PASSWD dbname=$DB_NAME" \
    $rep_data/phase_1_umap_trace_$layer.geojson -nln phase_1_trace_3857 -lco GEOMETRY_NAME=the_geom -explodecollections
  echo "  fait"
  echo ""


# fin de la boucle de lecture des layers umap
done < $rep_data/umap_phase_1_layers.txt


# PK VIP
# plus besoin en 2021 
#ogr2ogr -f "PostgreSQL" PG:"host=$DB_HOST user=$DB_USER password=$DB_PASSWD dbname=$DB_NAME" data/phase_1_umap_pk_vip.geojson -nln phase_1_pk_vip_3857 -lco GEOMETRY_NAME=the_geom -explodecollections -overwrite



echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Application des traitements SQL "
echo ""

# on crée les tables en 3948
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME < sql/phase_1_trace.sql  >> /dev/null

echo "  fait"
echo ""


echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Exports "
echo ""

echo "  exports geojson"
echo ""

# et on exporte vers Geojson
rm -f $rep_data/phase_1_pk_auto.geojson
ogr2ogr -f "GeoJSON" $rep_data/phase_1_pk_auto.geojson PG:"host=$DB_HOST port=$DB_PORT user=$DB_USER password=$DB_PASSWD dbname=$DB_NAME" phase_1_pk_auto_4326
rm -f $rep_data/phase_1_trace_4326.geojson
ogr2ogr -f "GeoJSON" $rep_data/phase_1_trace_4326.geojson PG:"host=$DB_HOST port=$DB_PORT user=$DB_USER password=$DB_PASSWD dbname=$DB_NAME" phase_1_trace_4326
# les fichiers sont ensuite tout de suite visible dans umap

# exports supplémentaires
rm -f $rep_data/phase_1_pk_auto.xlsx
ogr2ogr -f "XLSX" $rep_data/phase_1_pk_auto.xlsx PG:"host=$DB_HOST port=$DB_PORT user=$DB_USER password=$DB_PASSWD dbname=$DB_NAME" phase_1_pk_auto_4326

echo "  fait"
echo ""

echo ""
echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  F I N traitements phase 1"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
