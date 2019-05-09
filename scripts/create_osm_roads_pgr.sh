#!/bin/bash


echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Création de la couche osm_roads_pgr"
echo ""
echo ""

HOST_DB_redadeg=localhost
HOST_DB_osm=192.168.56.1

# suppose le le .pgpass est correctement configuré pour le compte qui lance ce script


echo ">> suppression de la topologie existante"
echo ""
#psql -h $HOST_DB_redadeg -U redadeg -d redadeg -c "SELECT DropTopology('osm_roads_topo') ;"
echo ""

# création d'un schéma qui va accueillir le réseau topologique de la couche osm_roads
echo ">> création d'une nouvelle topologie"
echo ""
#psql -h $HOST_DB_redadeg -U redadeg -d redadeg -c "SELECT topology.CreateTopology('osm_roads_topo', 2154);"


# on a donc un nouveau schéma osm_roads_topo qui contient 4 tables : edge_data, face, node, relation
# et un nouvel enregistrement dans la table topology.layer
# logiquement : c'est  1  mais on va quand même faire une requête

psql -X -h $HOST_DB_redadeg -U redadeg -d redadeg \
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

echo ">> ajout d'un nouvel attribut sur la table osm_roads"
echo ""
psql -h $HOST_DB_redadeg -U redadeg -d redadeg -c "SELECT topology.AddTopoGeometryColumn('osm_roads_topo', 'public', 'osm_roads', 'topo_geom', 'LINESTRING');"
echo ""
echo "fait"
echo ""

echo "fini  >>  exécuter update_osm_roads_pgr.sh "
echo ""
