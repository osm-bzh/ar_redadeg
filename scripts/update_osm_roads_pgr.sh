#!/bin/bash

set -e
set -u

PSQL=/usr/bin/psql
DB_HOST=localhost
DB_NAME=redadeg
DB_USER=redadeg


cd /data/www/vhosts/ar-redadeg_openstreetmap_bzh/htdocs/scripts/


echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Mise à jour des couches de routage"
echo ""
echo "  prend environ 5 min"
echo ""

# cette couche vient d'une base osm donc il faut la recharger
$PSQL -h $DB_HOST -U $DB_USER -d $DB_NAME -c "TRUNCATE TABLE public.osm_roads;"
$PSQL -h $DB_HOST -U $DB_USER -d $DB_NAME < data/osm_roads.sql


# maj de la topologie de la couche osm_roads_pgr qui sert au routage
$PSQL -h $DB_HOST -U $DB_USER -d $DB_NAME < update_osm_roads_pgr.sql

echo "fini"
echo ""


