#!/bin/bash

set -e
set -u

PSQL=/usr/bin/psql
DB_HOST=localhost
DB_NAME=redadeg
DB_USER=redadeg
DB_PASSWD=redadeg



echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Récupération des fichiers geojson depuis umap"

# le tracé manuel
curl -sS  http://umap.openstreetmap.fr/fr/datalayer/746021/ > data/phase_1_umap_trace.geojson
# PK VIP
curl -sS  http://umap.openstreetmap.fr/fr/datalayer/715179/ > data/phase_1_umap_pk_vip.geojson

echo "  fait"
echo ""

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# on charge dans postgis
# après avoir supprimé les tables

# note : les coordonnées sont en 3857 mais la déclaration de la table = 4326

echo "  chargement des fichiers dans la BD"
echo ""

$PSQL -h $DB_HOST -U $DB_USER -d $DB_NAME -c "DROP TABLE phase_1_trace_3857 CASCADE;"
ogr2ogr -f "PostgreSQL" PG:"host=localhost user=redadeg password=redadeg dbname=redadeg" data/phase_1_umap_trace.geojson -nln phase_1_trace_3857 -lco GEOMETRY_NAME=the_geom -explodecollections -overwrite

$PSQL -h $DB_HOST -U $DB_USER -d $DB_NAME -c "DROP TABLE phase_1_pk_vip_3857;"
ogr2ogr -f "PostgreSQL" PG:"host=localhost user=redadeg password=redadeg dbname=redadeg" data/phase_1_umap_pk_vip.geojson -nln phase_1_pk_vip_3857 -lco GEOMETRY_NAME=the_geom -explodecollections -overwrite

echo "  fait"
echo ""


echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Application des traitements SQL "
echo ""

# on crée les tables en 3948
$PSQL -h $DB_HOST -U $DB_USER -d $DB_NAME < traitements_phase_1.sql

echo "  fait"
echo ""


echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Exports et upload vers le serveur de diffusion"
echo ""

echo "  exports geojson"
echo ""

# et on exporte vers Geojson
rm data/phase_1_pk_auto.geojson
ogr2ogr -f "GeoJSON" data/phase_1_pk_auto.geojson PG:"host=$DB_HOST user=$DB_USER password=$DB_PASSWD dbname=$DB_NAME" phase_1_pk_auto_4326
rm data/phase_1_trace_4326.geojson
ogr2ogr -f "GeoJSON" data/phase_1_trace_4326.geojson PG:"host=$DB_HOST user=$DB_USER password=$DB_PASSWD dbname=$DB_NAME" phase_1_trace_4326
# les fichiers sont ensuite tout de suite visible dans umap

# exports supplémentaires
rm data/phase_1_pk_auto.xlsx
ogr2ogr -f "XLSX" data/phase_1_pk_auto.xlsx PG:"host=$DB_HOST user=$DB_USER password=$DB_PASSWD dbname=$DB_NAME" phase_1_pk_auto_4326

echo "  fait"
echo ""
echo "  upload"
echo ""

# upload
rsync -av -z data/phase_1_pk_auto.geojson data/phase_1_trace_4326.geojson data/phase_1_pk_auto.xlsx  breizhpovh2:/data/www/vhosts/ar-redadeg_openstreetmap_bzh/htdocs/scripts/data/

echo "  fait"
echo ""

echo ""
echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  F I N traitements phase 1"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
