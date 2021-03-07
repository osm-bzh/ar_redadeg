#!/bin/bash

# ce traitement consiste à exporter le tracé phase 3 qui a été recalculer
# avec un nommage phase 5
# puis pusk vers le serveur


set -e
set -u

#PSQL=/usr/bin/psql
PSQL=psql
DB_HOST=breizhpolenovo
DB_NAME=redadeg
DB_USER=redadeg
DB_PASS=redadeg



# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#  et on exporte en geojson pour umap et merour

echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Exports"
echo ""

echo "  exports geojson"
echo ""

rm data/phase_5_trace_secteurs.geojson
ogr2ogr -f "GeoJSON" data/phase_5_trace_secteurs.geojson PG:"host=$DB_HOST user=$DB_USER password=$DB_PASS dbname=$DB_NAME" \
-sql "SELECT * FROM phase_3_trace_secteurs_4326 ORDER BY secteur_id"

rm data/phase_5_trace_troncons.geojson
ogr2ogr -f "GeoJSON" data/phase_5_trace_troncons.geojson PG:"host=$DB_HOST user=$DB_USER password=$DB_PASS dbname=$DB_NAME" \
-sql "SELECT * FROM phase_3_trace_troncons_4326 ORDER BY troncon_id"


echo "  exports GML"
echo ""

rm data/phase_2_trace_pgr.gml
ogr2ogr -f "GML" data/phase_2_trace_pgr.gml PG:"host=$DB_HOST user=$DB_USER password=$DB_PASS dbname=$DB_NAME" \
-sql "SELECT * FROM phase_2_trace_pgr ORDER BY secteur_id, path_seq"



echo "  fait"
echo ""

echo "  pousse vers serveur"
echo ""

rsync -av -z data/phase_5_trace_secteurs.geojson data/phase_5_trace_troncons.geojson data/phase_2_trace_pgr.gml breizhpovh2:/data/www/vhosts/ar-redadeg_openstreetmap_bzh/htdocs/scripts/data/

echo ""
echo "  fait"
echo ""


echo ""
echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  F I N"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
