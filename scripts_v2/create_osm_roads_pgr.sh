#! /bin/bash

# exit dès que qqch se passe mal
set -e
# sortir si "unbound variable"
#set -u


if [ -z "$1" ]
  then
    echo "Pas de millésime en argument --> stop"
    exit 1
fi

# lecture du fichier de configuration
. config.sh


echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Création de la couche osm_roads_pgr"
echo ""
echo ""

# suppose le le .pgpass est correctement configuré pour le compte qui lance ce script


echo ">> suppression de la topologie existante"
echo ""
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT DropTopology('osm_roads_topo') ;" || true
echo ""

# création d'un schéma qui va accueillir le réseau topologique de la couche osm_roads
echo ">> création d'une nouvelle topologie"
echo ""
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT topology.CreateTopology('osm_roads_topo', 2154);"


echo ">> ajout d'un nouvel attribut sur la table osm_roads"
echo ""
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT topology.AddTopoGeometryColumn('osm_roads_topo', 'public', 'osm_roads', 'topo_geom', 'LINESTRING');"
echo ""
echo "fait"
echo ""

echo ""
echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  F I N "
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
echo ">>>>  exécuter update_osm_roads_pgr.sh "
echo ""
