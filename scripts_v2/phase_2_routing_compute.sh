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
echo "  Calcul de l'itinéraires pour le secteur $secteur_id"
echo ""


# on commence par vider la table qui contiendra les calculs d'itinéraires
echo "  vidage de la couche de routage"
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c \
  "DELETE FROM phase_2_trace_pgr WHERE secteur_id = $secteur_id ;" >> /dev/null
echo "  fait"
echo ""


# on cherche le node_id du PK de début et le node_id du PK de fin
read pk_start_node <<< $(PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME --no-align -t --quiet -c \
"SELECT pk.pgr_node_id 
FROM phase_2_pk_secteur pk JOIN secteur s ON pk.secteur_id = s.id
WHERE secteur_id IN ($secteur_id,$secteur_id_next)
ORDER BY s.id
LIMIT 1 OFFSET 0" )

read pk_end_node <<< $(PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME --no-align -t --quiet -c \
"SELECT pk.pgr_node_id 
FROM phase_2_pk_secteur pk JOIN secteur s ON pk.secteur_id = s.id
WHERE secteur_id IN ($secteur_id,$secteur_id_next)
ORDER BY s.id
LIMIT 1 OFFSET 1" )



echo "  calcul d'un itinéraire entre les nœuds $pk_start_node et $pk_end_node"


PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c \
"INSERT INTO phase_2_trace_pgr
SELECT
  $secteur_id AS secteur_id,
  -- info de routage
  a.path_seq,
  a.node,
  a.cost,
  a.agg_cost,
  -- infos OSM
  b.osm_id,
  b.highway,
  b.\"type\",
  b.oneway,
  b.ref,
  CASE
  WHEN b.name_fr IS NULL AND b.ref IS NOT NULL THEN b.ref
ELSE b.name_fr
  END AS name_fr,
  CASE
  WHEN b.name_br IS NULL AND b.name_fr IS NULL AND b.ref IS NOT NULL THEN b.ref
WHEN b.name_br IS NULL AND b.name_fr IS NOT NULL THEN '# da dreiñ e brezhoneg #'
ELSE b.name_br
  END AS name_br,
  b.the_geom
FROM pgr_dijkstra(
    'SELECT id, source, target, cost, reverse_cost FROM osm_roads_pgr', $pk_start_node, $pk_end_node) as a
JOIN osm_roads_pgr b ON a.edge = b.id ;" >> /dev/null


# ménage pour performances
PGPASSWORD=$DB_PASSWD $PSQL -X -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c \
  "VACUUM FULL phase_2_trace_pgr ;" >> /dev/null

# on fait une requête pour voir la longueur insérée
# en fait : la longueur totale - la longueur totale lors du précédent calcul
read longueur_inseree <<< $(PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME --no-align -t --quiet -c \
"SELECT 
  CASE 
    WHEN trunc(SUM(ST_Length(the_geom))/1000) IS NULL THEN 0
    ELSE trunc(SUM(ST_Length(the_geom))/1000)
  END AS longueur
FROM phase_2_trace_pgr WHERE secteur_id = $secteur_id;")


# une alerte si 0 km insérés
if [ $longueur_inseree -eq 0 ] ;
then
  echo "  >>> aucun itinéraire n'a pu être calculé <<<"
  echo "  :("
  echo ""
  exit 0
else
  echo "  fait : $longueur_inseree km calculés"
fi


echo ""
echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  F I N  calcul de l'itinéraire pour le secteur $secteur_id"
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
