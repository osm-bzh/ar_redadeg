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

PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -U $DB_USER -d $DB_NAME  < patch_osm_roads_pgr.sql

echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  F I N patch"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
