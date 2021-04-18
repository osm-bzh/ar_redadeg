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
echo "  Mise à jour des couches de routage"
echo ""
echo "  prend 15-20 min"
echo ""

# la couche osm_roads vient d'être mise à jour ou recrée

# on efface la topologie existante
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT DropTopology('osm_roads_topo') ;"

# création d'un schéma qui va accueillir le réseau topologique de la couche osm_roads
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT topology.CreateTopology('osm_roads_topo', 2154);"

# ajout d'un nouvel attribut sur la table osm_roads
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT topology.AddTopoGeometryColumn('osm_roads_topo', 'public', 'osm_roads', 'topo_geom', 'LINESTRING');"


# on a besoin du layer_id
# au cas où ça change : on le récupère par requête
PGPASSWORD=$DB_PASSWD $PSQL -X -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME \
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
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "UPDATE osm_roads SET topo_geom = topology.toTopoGeom(the_geom, 'osm_roads_topo', $layer_id, 0.00001);"
echo ""
echo "fait"
echo ""

echo ">> maj de la couche osm_roads_pgr qui sert au routage depuis la topologie"
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME < sql/update_osm_roads_pgr.sql

#echo ">> patch de la couche osm_roads_pgr pour les cas particuliers"
#$PSQL -h $DB_HOST -U $DB_USER -d $DB_NAME < patch_osm_roads_pgr.sql


echo ""
echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  F I N "
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
echo "/!\ patcher le filaire de voie si nécessaire"
echo ""
echo ""

