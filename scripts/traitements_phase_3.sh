#!/bin/bash

set -e
set -u

PSQL=/usr/bin/psql
DB_HOST=breizhpolenovo
DB_NAME=redadeg
DB_USER=redadeg
DB_PASSWD=redadeg



echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Création des données phase 3"
echo ""

# création des PK auto par découpage des tronçons de la phase 2
/Library/FME/2018.1/fme traitements_phase_3_decoupage.fmw

# en sortie on obtient :
# phase_3_pk_auto = couche de points
# phase_3_pk_sens_verif = couche de ligne direct PK à PK



# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#  et on exporte en geojson pour umap

echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Exports et upload vers le serveur de diffusion"
echo ""

echo "  exports geojson"
echo ""

rm data/phase_3_pk_auto.geojson
ogr2ogr -f "GeoJSON" data/phase_3_pk_auto.geojson PG:"host=$DB_HOST user=$DB_USER password=$DB_PASSWD dbname=$DB_NAME" phase_3_pk_auto_4326
rm data/phase_3_pk_sens_verif.geojson
ogr2ogr -f "GeoJSON" data/phase_3_pk_sens_verif.geojson PG:"host=$DB_HOST user=$DB_USER password=$DB_PASSWD dbname=$DB_NAME" phase_3_pk_sens_verif_4326
rm data/phase_3_trace_troncons.geojson
ogr2ogr -f "GeoJSON" data/phase_3_trace_troncons.geojson PG:"host=$DB_HOST user=$DB_USER password=$DB_PASSWD dbname=$DB_NAME" phase_3_trace_troncons_4326
rm data/phase_3_trace_secteurs.geojson
ogr2ogr -f "GeoJSON" data/phase_3_trace_secteurs.geojson PG:"host=$DB_HOST user=$DB_USER password=$DB_PASSWD dbname=$DB_NAME" phase_3_trace_secteurs_4326

echo "  fait"
echo ""
echo "  upload"
echo ""

# upload
rsync -av -z data/phase_3_*.geojson breizhpovh2:/data/www/vhosts/ar-redadeg_openstreetmap_bzh/htdocs/scripts/data/

echo "  fait"
echo ""

echo ""
echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  F I N traitements phase 3"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
