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


# contrôle si argument secteur_id
if [ -z "$2" ]
  then
    echo "Pas de secteur_id en argument --> stop"
    exit 1
fi

secteur_id=$2

# on calcule le code du secteur suivant
# ex : 200 -> 300 / 900 -> 1000

secteur_id_len=${#secteur_id}

if [ $secteur_id_len == 2 ]
then secteur_id_next="$(( ${secteur_id:0:1} + 1 ))0"
elif [ $secteur_id_len == 3 ]
then secteur_id_next="$(( ${secteur_id:0:1} + 1 ))00"
elif [ $secteur_id_len == 4 ]
then secteur_id_next="$(( ${secteur_id:0:1} + 1 ))000"
fi


echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Mise à jour des couches de routage pour le secteur $secteur_id -> $secteur_id_next"
echo ""
echo ""

# # la couche osm_roads vient d'être mise à jour ou recrée

# # on efface la topologie existante
# $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT DropTopology('osm_roads_topo') ;"

# # création d'un schéma qui va accueillir le réseau topologique de la couche osm_roads
# $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT topology.CreateTopology('osm_roads_topo', 2154);"

# # ajout d'un nouvel attribut sur la table osm_roads
# $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT topology.AddTopoGeometryColumn('osm_roads_topo', 'public', 'osm_roads', 'topo_geom', 'LINESTRING');"


# # on a besoin du layer_id
# # au cas où ça change : on le récupère par requête
# $PSQL -X -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME \
#     -c "SELECT layer_id FROM topology.layer WHERE table_name = 'osm_roads' ;" \
#     --single-transaction \
#     --set AUTOCOMMIT=off \
#     --set ON_ERROR_STOP=on \
#     --no-align \
#     -t \
#     --field-separator ' ' \
#     --quiet | while read -a Record ; do

#   layer_id=${Record[0]}

#   echo ""
#   echo "layer_id de osm_roads = $layer_id"
#   echo ""
    
# done

# sauf que je n'arrive pas à sortir cette valeur du subshell créé par la boucle do /!\
# donc je remet ici à la main. A corriger… TODO
layer_id=1


echo "  suppression des données du secteur à mettre à jour"
$PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c \
  "DELETE FROM osm_roads WHERE secteur_id >= $secteur_id AND secteur_id < $secteur_id_next ;"
$PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c \
  "DELETE FROM osm_roads_pgr WHERE secteur_id >= $secteur_id AND secteur_id < $secteur_id_next ;"
echo "  fait"
echo ""


echo "  import du filaire de voirie à jour dans la couche topologique (osm_roads)"

# import des données
$PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c \
"INSERT INTO osm_roads 
  SELECT secteur_id, osm_id, highway, "type", oneway, "ref", name_fr, name_br, the_geom, NULL AS topo_geom 
  FROM osm_roads_import"

# on calcule le graphe topologique en remplissant le nouvel attribut géométrique
# pour le secteur en cours de mise à jour uniquement
# le 1er chiffre est l'identifiant du layer dans la table topology.layer
# le 2e chiffre est la tolérance en mètres
$PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c \
"UPDATE osm_roads SET topo_geom = topology.toTopoGeom(the_geom, 'osm_roads_topo', $layer_id, 0.00001) "\
"WHERE secteur_id >= $secteur_id AND secteur_id < $secteur_id_next ;"

echo "fait"
echo ""

#echo ">> maj de la couche osm_roads_pgr qui sert au routage depuis la topologie"
#$PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME < sql/update_osm_roads_pgr.sql


echo "  remplissage de la couche de routage (osm_roads_pgr)"
$PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c \
"INSERT INTO osm_roads_pgr
(
  SELECT 
    nextval('osm_roads_pgr_id_seq'),
    o.secteur_id,
    o.osm_id,
    o.highway,
    o.type,
    o.oneway,
    o.ref,
    o.name_fr,
    o.name_br,
    NULL as source,
    NULL as target,
    NULL as cost,
    NULL as reverse_cost,
    e.geom as the_geom
  FROM osm_roads_topo.edge e,
       osm_roads_topo.relation rel,
       osm_roads o
  WHERE 
    o.secteur_id >= $secteur_id AND o.secteur_id < $secteur_id_next
    AND e.edge_id = rel.element_id
    AND rel.topogeo_id = (o.topo_geom).id
);"

echo "  calcul de la topologie sur ces nouveaux tronçons"
$PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c \
"SELECT pgr_createTopology('osm_roads_pgr', 0.001, rows_where:='true', clean:=false);"
echo "fait"
echo ""

echo "  calcul des 2 attributs de coût (= longueur)"
$PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "
UPDATE osm_roads_pgr 
SET cost = round(st_length(the_geom)::numeric), reverse_cost = round(st_length(the_geom)::numeric)
WHERE secteur_id = $secteur_id ;"
echo "fait"
echo ""



echo ""
echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  F I N "
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
echo ""

