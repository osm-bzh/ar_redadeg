#!/bin/bash

# ce traitement consiste à charger les données des 10 cartes umap
# à les contrôler par rapport aux données de référence
# à les agréger
# puis les exporter pour merour


set -e
set -u

PSQL=/usr/bin/psql
DB_HOST=192.168.56.131
DB_NAME=redadeg
DB_USER=redadeg
DB_PASS=redadeg


#cd /data/www/vhosts/ar-redadeg_openstreetmap_bzh/htdocs/scripts/


echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Chargement des données des cartes umap"
echo ""
echo ""

  
  # OK !
  #dernierFichierCmd="ls -l1dt phase_5_pk_secteur_"$secteur"_* | head -1"
  #eval $dernierFichierCmd
  

# on procède secteur par secteur
# on récupère les données umap et on les charge dans la même couche

# on commence donc par vider la couche cible
# géré avec l'option -overwrite sur le secteur 1


echo "    secteur 1"
curl -sS http://umap.openstreetmap.fr/fr/datalayer/1027042/ > data/phase_5_pk_umap_tmp.geojson
# chargement initial
ogr2ogr -f "PostgreSQL" PG:"host=$DB_HOST user=$DB_USER password=$DB_PASS dbname=$DB_NAME" \
data/phase_5_pk_umap_tmp.geojson -nln phase_5_pk_umap -lco GEOMETRY_NAME=the_geom -explodecollections -overwrite


echo "    secteur 2"
curl -sS http://umap.openstreetmap.fr/fr/datalayer/1027081/ > data/phase_5_pk_umap_tmp.geojson
# on rajoute à la couche
ogr2ogr -f "PostgreSQL" PG:"host=$DB_HOST user=$DB_USER password=$DB_PASS dbname=$DB_NAME" \
data/phase_5_pk_umap_tmp.geojson -nln phase_5_pk_umap -explodecollections -append


echo "    secteur 3"
curl -sS http://umap.openstreetmap.fr/fr/datalayer/1027101/ > data/phase_5_pk_umap_tmp.geojson
# on rajoute à la couche
ogr2ogr -f "PostgreSQL" PG:"host=$DB_HOST user=$DB_USER password=$DB_PASS dbname=$DB_NAME" \
data/phase_5_pk_umap_tmp.geojson -nln phase_5_pk_umap -explodecollections -append


echo "    secteur 4"
curl -sS http://umap.openstreetmap.fr/fr/datalayer/1027104/ > data/phase_5_pk_umap_tmp.geojson
# on rajoute à la couche
ogr2ogr -f "PostgreSQL" PG:"host=$DB_HOST user=$DB_USER password=$DB_PASS dbname=$DB_NAME" \
data/phase_5_pk_umap_tmp.geojson -nln phase_5_pk_umap -explodecollections -append


echo "    secteur 5"
curl -sS http://umap.openstreetmap.fr/fr/datalayer/1027107/ > data/phase_5_pk_umap_tmp.geojson
# on rajoute à la couche
ogr2ogr -f "PostgreSQL" PG:"host=$DB_HOST user=$DB_USER password=$DB_PASS dbname=$DB_NAME" \
data/phase_5_pk_umap_tmp.geojson -nln phase_5_pk_umap -explodecollections -append


echo "    secteur 6"
curl -sS http://umap.openstreetmap.fr/fr/datalayer/1027110/ > data/phase_5_pk_umap_tmp.geojson
# on rajoute à la couche
ogr2ogr -f "PostgreSQL" PG:"host=$DB_HOST user=$DB_USER password=$DB_PASS dbname=$DB_NAME" \
data/phase_5_pk_umap_tmp.geojson -nln phase_5_pk_umap -explodecollections -append


echo "    secteur 7"
curl -sS http://umap.openstreetmap.fr/fr/datalayer/1027114/ > data/phase_5_pk_umap_tmp.geojson
# on rajoute à la couche
ogr2ogr -f "PostgreSQL" PG:"host=$DB_HOST user=$DB_USER password=$DB_PASS dbname=$DB_NAME" \
data/phase_5_pk_umap_tmp.geojson -nln phase_5_pk_umap -explodecollections -append


echo "    secteur 8"
curl -sS http://umap.openstreetmap.fr/fr/datalayer/1027117/ > data/phase_5_pk_umap_tmp.geojson
# on rajoute à la couche
ogr2ogr -f "PostgreSQL" PG:"host=$DB_HOST user=$DB_USER password=$DB_PASS dbname=$DB_NAME" \
data/phase_5_pk_umap_tmp.geojson -nln phase_5_pk_umap -explodecollections -append


echo "    secteur 9"
curl -sS http://umap.openstreetmap.fr/fr/datalayer/1027120/ > data/phase_5_pk_umap_tmp.geojson
# on rajoute à la couche
ogr2ogr -f "PostgreSQL" PG:"host=$DB_HOST user=$DB_USER password=$DB_PASS dbname=$DB_NAME" \
data/phase_5_pk_umap_tmp.geojson -nln phase_5_pk_umap -explodecollections -append


echo "    secteur 10"
curl -sS http://umap.openstreetmap.fr/fr/datalayer/1027123/ > data/phase_5_pk_umap_tmp.geojson
# on rajoute à la couche
ogr2ogr -f "PostgreSQL" PG:"host=$DB_HOST user=$DB_USER password=$DB_PASS dbname=$DB_NAME" \
data/phase_5_pk_umap_tmp.geojson -nln phase_5_pk_umap -explodecollections -append




echo ""
echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  F I N"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
