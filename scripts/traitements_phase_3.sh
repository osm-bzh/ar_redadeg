#!/bin/bash

set -e
set -u

# argument 1 = millesime redadeg
millesime=$1

# linux
#PSQL=/usr/bin/psql
# mac via brew
PSQL=/usr/local/bin/psql

DB_HOST=localhost
DB_PORT=55432
DB_NAME=redadeg_$millesime
DB_USER=redadeg
DB_PASSWD=redadeg

# server bed110
#rep_scripts='/data/projets/ar_redadeg/scripts/'
# mac
rep_scripts='/Volumes/ker/mael/projets/osm_bzh/github/ar_redadeg/scripts'

echo "rep_scripts = $rep_scripts"
# variables liées au millésimes
echo "millesime de travail = $1"
rep_data=../data/$millesime
echo "rep_data = $rep_data"
echo "base de données = $DB_NAME sur $DB_HOST:$DB_PORT"
echo ""

exit 1


echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Création des données phase 3"
echo ""

# création des PK auto par découpage des tronçons de la phase 2
/Library/FME/2021.0/fme traitements_phase_3_decoupage.fmw

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

rm $rep_data/phase_3_pk_auto.geojson
ogr2ogr -f "GeoJSON" $rep_data/phase_3_pk_auto.geojson PG:"host=$DB_HOST user=$DB_USER password=$DB_PASSWD dbname=$DB_NAME" phase_3_pk_auto_4326
rm $rep_data/phase_3_pk_sens_verif.geojson
ogr2ogr -f "GeoJSON" $rep_data/phase_3_pk_sens_verif.geojson PG:"host=$DB_HOST user=$DB_USER password=$DB_PASSWD dbname=$DB_NAME" phase_3_pk_sens_verif_4326
rm $rep_data/phase_3_trace_troncons.geojson
ogr2ogr -f "GeoJSON" $rep_data/phase_3_trace_troncons.geojson PG:"host=$DB_HOST user=$DB_USER password=$DB_PASSWD dbname=$DB_NAME" phase_3_trace_troncons_4326
rm $rep_data/phase_3_trace_secteurs.geojson
ogr2ogr -f "GeoJSON" $rep_data/phase_3_trace_secteurs.geojson PG:"host=$DB_HOST user=$DB_USER password=$DB_PASSWD dbname=$DB_NAME" phase_3_trace_secteurs_4326

echo "  fait"
echo ""
echo "  upload"
echo ""

# upload
rsync -av -z $rep_data/phase_3_*.geojson bed100.bedniverel.bzh:/data/projets/ar_redadeg/data/$millesime/

echo "  fait"
echo ""

echo ""
echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  F I N traitements phase 3"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
