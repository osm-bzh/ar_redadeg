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
# après avoir calculé un itinéraire on va créer des données dérivées
#

echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Début post-traitements phase 2 pour le secteur $secteur_id"
echo ""


echo "  création d'une ligne unique par secteur"


PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c \
  "DELETE FROM phase_2_trace_secteur WHERE secteur_id = $secteur_id ;" >> /dev/null

PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c \
"WITH trace_ordered AS (
  SELECT secteur_id, the_geom
  FROM phase_2_trace_pgr
  WHERE secteur_id = $secteur_id
  ORDER BY secteur_id, path_seq
)
INSERT INTO phase_2_trace_secteur
  SELECT
    secteur_id, '', '', 0, 0,
    ST_CollectionExtract(ST_UNION(the_geom),2) AS the_geom
  FROM trace_ordered
  GROUP BY secteur_id
  ORDER BY secteur_id ;" >> /dev/null

# mise à jour des attributs
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c \
"UPDATE phase_2_trace_secteur a
SET 
  nom_fr = b.nom_fr,
  nom_br = b.nom_br,
  longueur = TRUNC( ST_Length(the_geom)::numeric , 0),
  longueur_km = TRUNC( ST_Length(the_geom)::numeric / 1000 , 1)
FROM secteur b 
WHERE a.secteur_id = b.id AND a.secteur_id = $secteur_id ;" >> /dev/null

echo "  fait"


echo ""
echo "  Export GeoJSON pour umap"
rm -f $rep_data/phase_2_trace_secteur.geojson
ogr2ogr -f "GeoJSON" $rep_data/phase_2_trace_secteur.geojson PG:"host=$DB_HOST port=$DB_PORT user=$DB_USER password=$DB_PASSWD dbname=$DB_NAME" phase_2_trace_secteur_4326
echo "  fait"


echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  F I N  post-traitements phase 2 pour le secteur $secteur_id"
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
