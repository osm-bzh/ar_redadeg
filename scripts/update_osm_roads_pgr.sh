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
echo "  Mise à jour des couches de routage"
echo ""
echo "  prend 15-20 min"
echo ""

# la couche osm_roads vient d'être mise à jour ou recrée

# on efface la topologie existante
$PSQL -h $DB_HOST -U $DB_USER -d $DB_NAME -c "SELECT DropTopology('osm_roads_topo') ;"

# création d'un schéma qui va accueillir le réseau topologique de la couche osm_roads
$PSQL -h $DB_HOST -U $DB_USER -d $DB_NAME -c "SELECT topology.CreateTopology('osm_roads_topo', 2154);"

# ajout d'un nouvel attribut sur la table osm_roads
$PSQL -h $DB_HOST -U $DB_USER -d $DB_NAME -c "SELECT topology.AddTopoGeometryColumn('osm_roads_topo', 'public', 'osm_roads', 'topo_geom', 'LINESTRING');"


# on a besoin du layer_id
# au cas où ça change : on le récupère par requête
$PSQL -X -h $DB_HOST -U $DB_USER -d $DB_NAME \
    -c "SELECT layer_id FROM topology.layer WHERE table_name = 'osm_roads' ;" \
    --single-transaction \
    --set AUTOCOMMIT=off \
    --set ON_ERROR_STOP=on \
    --no-align \
    -t \
    --field-separator ' ' \
    --quiet | while read -a Record ; do

  layer_id=${Record[0]}

  echo ""
  echo "layer_id de osm_roads = $layer_id"
  echo ""
    
done

# sauf que je n'arrive pas à sortir cette valeur du subshell créé par la boucle do /!\
# donc je remet ici à la main. A corriger… TODO
layer_id=1


# on calcule le graphe topologique en remplissant le nouvel attribut géométrique
# le 1er chiffre est l'identifiant du layer dans la table topology.layer
# le 2e chiffre est la tolérance en mètres
echo ">> calcul du graphe topologique"
$PSQL -h $DB_HOST -U $DB_USER -d $DB_NAME -c "UPDATE osm_roads SET topo_geom = topology.toTopoGeom(the_geom, 'osm_roads_topo', $layer_id, 0.00001);"
echo ""
echo "fait"
echo ""

echo ">> maj de la couche osm_roads_pgr qui sert au routage depuis la topologie"
$PSQL -h $DB_HOST -U $DB_USER -d $DB_NAME < update_osm_roads_pgr.sql

#echo ">> patch de la couche osm_roads_pgr pour les cas particuliers"
#$PSQL -h $DB_HOST -U $DB_USER -d $DB_NAME < patch_osm_roads_pgr.sql

echo "/!\ patcher le filaire de voie si nécessaire"

echo ""
echo "fini"
echo ""


