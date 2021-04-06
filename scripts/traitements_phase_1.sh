#!/bin/bash

set -e
set -u

# argument 1 = millesime redadeg
millesime=$1

PSQL=/usr/bin/psql
DB_HOST=localhost
DB_NAME=redadeg_$millesime
DB_USER=redadeg
DB_PASSWD=redadeg

rep_scripts='/data/projets/ar_redadeg/scripts/'
echo "rep_scripts = $rep_scripts"
# variables liées au millésimes
echo "millesime de travail = $1"
rep_data=../data/$millesime
echo "rep_data = $rep_data"
echo "base de données = $DB_NAME"
echo ""


echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Récupération des fichiers geojson depuis umap"

# traitement des tracés manuels

# on commence par supprimer la table
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -U $DB_USER -d $DB_NAME -c "DROP TABLE IF EXISTS phase_1_trace_3857 CASCADE;"
#$PSQL -h $DB_HOST -U $DB_USER -d $DB_NAME -c "DROP TABLE IF EXISTS phase_1_pk_vip_3857;"
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
  ogr2ogr -f "PostgreSQL" PG:"host=$DB_HOST user=$DB_USER password=$DB_PASSWD dbname=$DB_NAME" $rep_data/phase_1_umap_trace_$layer.geojson -nln phase_1_trace_3857 -lco GEOMETRY_NAME=the_geom -explodecollections
  echo "  fait"
  echo ""


# fin de la boucle de lecture des layers umap
done < $rep_data/umap_phase_1_layers.txt


# PK VIP
# pas besoin en 2021
#ogr2ogr -f "PostgreSQL" PG:"host=$DB_HOST user=$DB_USER password=$DB_PASSWD dbname=$DB_NAME" data/phase_1_umap_pk_vip.geojson -nln phase_1_pk_vip_3857 -lco GEOMETRY_NAME=the_geom -explodecollections -overwrite



echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Application des traitements SQL "
echo ""

# on crée les tables en 3948
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -U $DB_USER -d $DB_NAME < $rep_scripts/traitements_phase_1.sql

echo "  fait"
echo ""


echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Exports "
echo ""

echo "  exports geojson"
echo ""

# et on exporte vers Geojson
rm -f $rep_data/phase_1_pk_auto.geojson
ogr2ogr -f "GeoJSON" $rep_data/phase_1_pk_auto.geojson PG:"host=$DB_HOST user=$DB_USER password=$DB_PASSWD dbname=$DB_NAME" phase_1_pk_auto_4326
rm -f $rep_data/phase_1_trace_4326.geojson
ogr2ogr -f "GeoJSON" $rep_data/phase_1_trace_4326.geojson PG:"host=$DB_HOST user=$DB_USER password=$DB_PASSWD dbname=$DB_NAME" phase_1_trace_4326
# les fichiers sont ensuite tout de suite visible dans umap

# exports supplémentaires
rm -f $rep_data/phase_1_pk_auto.xlsx
ogr2ogr -f "XLSX" $rep_data/phase_1_pk_auto.xlsx PG:"host=$DB_HOST user=$DB_USER password=$DB_PASSWD dbname=$DB_NAME" phase_1_pk_auto_4326

echo "  fait"
echo ""

echo ""
echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  F I N traitements phase 1"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
