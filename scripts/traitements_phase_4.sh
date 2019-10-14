#!/bin/bash

# ce traitement consiste à exporter les données tracé et PK auto de la phase 4 pour alimenter autant de cartes Umap que de secteurs.
# ces cartes umap servent en phase 5 à modifier le placement des PK
# phase 5 = gestion manuelle des PK


set -e
set -u

PSQL=/usr/bin/psql
DB_HOST=192.168.56.131
DB_NAME=redadeg
DB_USER=redadeg



#cd /data/www/vhosts/ar-redadeg_openstreetmap_bzh/htdocs/scripts/


echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Création des données phase 4"
echo ""
echo "  exports geojson par secteurs"
echo ""


ogr2ogr -f "GeoJSON" data/phase_4_pk_secteur_01.geojson PG:"host=$DB_HOST user=redadeg password=redadeg dbname=redadeg" phase_4_pk_auto_4326 -where "secteur_id = 10"


ogr2ogr -f "GeoJSON" data/phase_4_pk_secteur_02.geojson PG:"host=$DB_HOST user=redadeg password=redadeg dbname=redadeg" phase_4_pk_auto_4326 -where "secteur_id = 20"


ogr2ogr -f "GeoJSON" data/phase_4_pk_secteur_03.geojson PG:"host=$DB_HOST user=redadeg password=redadeg dbname=redadeg" phase_4_pk_auto_4326 -where "secteur_id = 30"


ogr2ogr -f "GeoJSON" data/phase_4_pk_secteur_04.geojson PG:"host=$DB_HOST user=redadeg password=redadeg dbname=redadeg" phase_4_pk_auto_4326 -where "secteur_id = 40"


ogr2ogr -f "GeoJSON" data/phase_4_pk_secteur_05.geojson PG:"host=$DB_HOST user=redadeg password=redadeg dbname=redadeg" phase_4_pk_auto_4326 -where "secteur_id = 50"


ogr2ogr -f "GeoJSON" data/phase_4_pk_secteur_06.geojson PG:"host=$DB_HOST user=redadeg password=redadeg dbname=redadeg" phase_4_pk_auto_4326 -where "secteur_id >= 60 and secteur_id < 70"


ogr2ogr -f "GeoJSON" data/phase_4_pk_secteur_07.geojson PG:"host=$DB_HOST user=redadeg password=redadeg dbname=redadeg" phase_4_pk_auto_4326 -where "secteur_id >= 70 and secteur_id < 80"


ogr2ogr -f "GeoJSON" data/phase_4_pk_secteur_08.geojson PG:"host=$DB_HOST user=redadeg password=redadeg dbname=redadeg" phase_4_pk_auto_4326 -where "secteur_id >= 80 and secteur_id < 90"


ogr2ogr -f "GeoJSON" data/phase_4_pk_secteur_09.geojson PG:"host=$DB_HOST user=redadeg password=redadeg dbname=redadeg" phase_4_pk_auto_4326 -where "secteur_id >= 90 and secteur_id < 100"


ogr2ogr -f "GeoJSON" data/phase_4_pk_secteur_10.geojson PG:"host=$DB_HOST user=redadeg password=redadeg dbname=redadeg" phase_4_pk_auto_4326 -where "secteur_id >= 100 and secteur_id < 110"


echo "  fait"
echo ""

echo "  pousse vers serveur"
echo ""

rsync -av -z data/phase_4_*.geojson breizhpovh2:/data/www/vhosts/ar-redadeg_openstreetmap_bzh/htdocs/scripts/data/

echo ""
echo "  fait"
echo ""


echo ""
echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  F I N"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
