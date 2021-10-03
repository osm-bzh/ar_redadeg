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
# ex : 200 -> 300
secteur_id_next="$(( ${secteur_id:0:1} + 1 ))00"



# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# ici on va calculer un itinéraire pour chaque secteur
# en utilisant les PK de début (ou fin) de chaque secteur

# https://www.manniwood.com/postgresql_and_bash_stuff/index.html


echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Patch de la couche osm_roads_pgr pour les cas particuliers"
echo ""


echo "  suppression des objets de osm_roads_pgr qui intersectent avec les zones de boucles"
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c \
"DELETE FROM osm_roads_pgr WHERE id IN
(
  SELECT a.id 
  FROM osm_roads_pgr a, osm_roads_pgr_patch_mask m
  WHERE 
    a.secteur_id = $secteur_id
    AND ST_INTERSECTS(a.the_geom, m.the_geom)
);"
echo "  fait"
echo ""


echo "  collage des objets de la couche osm_roads_pgr_patch à la place des objets supprimés"
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c \
"INSERT INTO osm_roads_pgr
  SELECT
    nextval('osm_roads_pgr_id_seq') AS uid,
    $secteur_id AS secteur_id,
    a.osm_id, a.highway, a.type, a.oneway, a.ref, a.name_fr, a.name_br,
    NULL, NULL, NULL, NULL,
    a.the_geom
  FROM osm_roads_pgr_patch a, osm_roads_pgr_patch_mask m
  WHERE ST_INTERSECTS(a.the_geom, m.the_geom);"
echo "  fait"
echo ""


echo "  calcul des 2 attributs de coût (= longueur)"
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "
UPDATE osm_roads_pgr 
SET cost = st_length(the_geom), reverse_cost = st_length(the_geom)
WHERE secteur_id = $secteur_id ;"

echo "  recrée des nœuds uniquement sur les zones de patch"
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c \
"SELECT pgr_nodeNetwork('osm_roads_pgr', 0.001, rows_where:='true');"

echo "  recalcul la topologie pgRouting uniquement sur les zones de patch"
# avec nettoyage de la topologie précédente
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c \
"SELECT pgr_createTopology('osm_roads_pgr', 0.001, rows_where:='true', clean:=false);"


# ensuite : on met un coût ÉNORME sur les tronçons ciblés par la couche de points de nettoyage
# AVANT de calculer les itinéraires
echo "  nettoyage de la couche de routage par les points ciblés"
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c \
"UPDATE osm_roads_pgr SET cost = 1000000, reverse_cost = 1000000 
WHERE 
  secteur_id = $secteur_id
  AND id IN (SELECT r.id FROM osm_roads_pgr r JOIN phase_2_point_nettoyage p ON r.id = p.edge_id);"
echo "  fait"
echo ""


# on recale les PK secteur et les points de nettoyage que maitenant
# car on vient de maj la topologie de routage

echo "  recalage des PK secteurs sur un nœud du réseau routable"
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME < sql/phase_2.1_recalage_pk_secteurs.sql
echo "  fait"
echo ""


echo "  recalage des points de nettoyage sur un nœud du réseau routable"
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME < sql/phase_2.2_recalage_points_nettoyage.sql
echo "  TODO"
echo ""



echo ""
echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  F I N  préparation pour le calcul d'un itiniraire pour le secteur $secteur_id"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
