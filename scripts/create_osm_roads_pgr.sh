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


echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Création de la couche osm_roads_pgr"
echo ""
echo ""

# suppose le le .pgpass est correctement configuré pour le compte qui lance ce script


echo ">> suppression de la topologie existante"
echo ""
$PSQL -h $DB_HOST -U $DB_USER -d $DB_NAME -c "SELECT DropTopology('osm_roads_topo') ;" || true
echo ""

# création d'un schéma qui va accueillir le réseau topologique de la couche osm_roads
echo ">> création d'une nouvelle topologie"
echo ""
$PSQL -h $DB_HOST -U $DB_USER -d $DB_NAME -c "SELECT topology.CreateTopology('osm_roads_topo', 2154);"


echo ">> ajout d'un nouvel attribut sur la table osm_roads"
echo ""
$PSQL -h $DB_HOST -U $DB_USER -d $DB_NAME -c "SELECT topology.AddTopoGeometryColumn('osm_roads_topo', 'public', 'osm_roads', 'topo_geom', 'LINESTRING');"
echo ""
echo "fait"
echo ""


echo "fini  >>  exécuter update_osm_roads_pgr.sh "
echo ""
