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
echo "  Création de la couche osm_roads pour le secteur $secteur_id -> $secteur_id_next"
echo ""
echo ""

echo ""
echo "import phase_1_trace dans la base OSM"
echo ""

# 1. export du tracé phase 1 depuis la base redadeg
pg_dump --dbname=postgresql://$DB_USER:$DB_PASSWD@$DB_HOST:$DB_PORT/$DB_NAME \
    --format=p --no-owner --section=pre-data --section=data --no-privileges --no-tablespaces --no-unlogged-table-data --no-comments \
    --table phase_1_trace \
    --file $rep_data/sql/redadeg_trace.sql


# 2. import dans la base OSM
PGPASSWORD=$osmDBPassword $PSQL -h $osmDBHost -p $osmDBPort -U $osmDBUser -d $osmDBName -c "DROP TABLE IF EXISTS phase_1_trace_$millesime ;"
PGPASSWORD=$osmDBPassword $PSQL -h $osmDBHost -p $osmDBPort -U $osmDBUser -d $osmDBName < $rep_data/sql/redadeg_trace.sql
PGPASSWORD=$osmDBPassword $PSQL -h $osmDBHost -p $osmDBPort -U $osmDBUser -d $osmDBName -c "ALTER TABLE phase_1_trace RENAME TO phase_1_trace_$millesime ;"

echo ""
echo "fait"
echo ""


# 3. calcul de la couche osm_roads = intersection buffer trace et routes OSM

echo ">> calcul de la couche osm_roads"
echo ""

# on supprime puis on recrée la table
PGPASSWORD=$osmDBPassword $PSQL -h $osmDBHost -p $osmDBPort -U $osmDBUser -d $osmDBName -c "DROP TABLE IF EXISTS osm_roads_$millesime ;"
PGPASSWORD=$osmDBPassword $PSQL -h $osmDBHost -p $osmDBPort -U $osmDBUser -d $osmDBName -c "
CREATE TABLE osm_roads_$millesime
(
  secteur_id integer NOT NULL,
  osm_id bigint,
  highway text,
  type text,
  oneway text,
  ref text,
  name_fr text,
  name_br text,
  the_geom geometry,
  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'LINESTRING'::text OR geometrytype(the_geom) = 'MULTILINESTRING'::text),
  CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 2154)
);"

echo ""
echo "  table osm_roads_$millesime créée"
echo ""
echo "  extraction du filaire de voies OSM le long du tracé fourni"
echo ""

PGPASSWORD=$osmDBPassword $PSQL -h $osmDBHost -p $osmDBPort -U $osmDBUser -d $osmDBName -c "
WITH trace_buffer AS (
  SELECT
    secteur_id,
    ST_Union(ST_Buffer(the_geom, 25, 'quad_segs=2')) AS the_geom
  FROM phase_1_trace_$millesime
  WHERE secteur_id >= $secteur_id AND secteur_id < $secteur_id_next
  GROUP BY secteur_id
  ORDER BY secteur_id
)
INSERT INTO osm_roads_$millesime
(
  SELECT
    t.secteur_id,
    osm_id,
    highway,
    CASE 
        WHEN highway IN ('motorway', 'trunk') THEN 'motorway' 
        WHEN highway IN ('primary', 'secondary') THEN 'mainroad' 
        WHEN highway IN ('motorway_link', 'trunk_link', 'primary_link', 'secondary_link', 'tertiary', 'tertiary_link', 'residential', 'unclassified', 'road', 'living_street') THEN 'minorroad' 
        WHEN highway IN ('service', 'track') THEN 'service' 
        WHEN highway IN ('path', 'cycleway', 'footway', 'pedestrian', 'steps', 'bridleway') THEN 'noauto' 
        ELSE 'other' 
    END AS type,
    oneway,
    ref,
    name AS name_fr,
    COALESCE(tags -> 'name:br'::text) as name_br,
    ST_Intersection(ST_Transform(o.way,2154), t.the_geom) AS the_geom
  FROM planet_osm_line o, trace_buffer t
  WHERE highway IS NOT NULL AND ST_INTERSECTS(t.the_geom, ST_Transform(o.way,2154))
) ;"

echo ""
echo "fait"
echo ""



# 4. export de osm_roads depuis la base OSM

echo "transfert de osm_roads_$millesime + secteur $secteur_id depuis la base OSM vers la base redadeg"
echo ""

pg_dump --dbname=postgresql://$osmDBUser:$osmDBPassword@$osmDBHost:$osmDBPort/$osmDBName \
    --format=p --no-owner --section=pre-data --section=data --no-privileges --no-tablespaces --no-unlogged-table-data --no-comments \
    --table osm_roads_$millesime \
    --file $rep_data/sql/osm_roads.sql


# 5. import dans la base redadeg
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "DROP TABLE IF EXISTS osm_roads_import;"
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME < $rep_data/sql/osm_roads.sql
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "ALTER TABLE osm_roads_$millesime RENAME TO osm_roads_import ;"

echo ""
echo "fait"
echo ""

echo "fini"

echo ""
echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  F I N "
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""