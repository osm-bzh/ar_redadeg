#!/bin/bash


echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Création de la couche osm_roads"
echo ""
echo ""

HOST_DB_redadeg=localhost
HOST_DB_osm=localhost

# suppose le le .pgpass est correctement configuré pour le compte qui lance ce script


echo "import phase_1_trace dans la base OSM"
echo ""

# 1. export du tracé phase 1 depuis la base redadeg
pg_dump --file data/redadeg_trace.sql --host $HOST_DB_redadeg --username redadeg --no-password --format=p --no-owner --section=pre-data --section=data --no-privileges --no-tablespaces --no-unlogged-table-data --no-comments --table public.phase_1_trace redadeg


# 2. import dans la base OSM
psql -h $HOST_DB_osm -U osmbr -d osm -c "DROP TABLE public.phase_1_trace;"
psql -h $HOST_DB_osm -U osmbr -d osm < data/redadeg_trace.sql

echo ""
echo "fait"
echo ""


# 3. calcul de la couche osm_roads = intersection buffer trace et routes OSM

echo ">> calcul de la couche osm_roads"
echo ""

# on supprime puis on recrée la table
psql -h $HOST_DB_osm -U osmbr -d osm -c "DROP TABLE IF EXISTS osm_roads ;"
psql -h $HOST_DB_osm -U osmbr -d osm -c "
CREATE TABLE osm_roads
(
  uid bigint NOT NULL,
  osm_id bigint,
  highway text,
  type text,
  oneway text,
  ref text,
  name_fr text,
  name_br text,
  the_geom geometry,
  CONSTRAINT osm_roads_pkey PRIMARY KEY (uid),
  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'LINESTRING'::text OR geometrytype(the_geom) = 'MULTILINESTRING'::text),
  CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 2154)
);"

echo ""
echo "  table osm_roads créée"
echo ""
echo "  chargement des données"
echo ""

psql -h $HOST_DB_osm -U osmbr -d osm -c "WITH trace_buffer AS (
  SELECT
    secteur_id,
    ST_Union(ST_Buffer(the_geom, 25, 'quad_segs=2')) AS the_geom
  FROM phase_1_trace
  GROUP BY secteur_id
  ORDER BY secteur_id
)
INSERT INTO osm_roads
(
  SELECT
    row_number() over() as id,
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

echo "transfert de osm_roads depuis la base OSM vers la base redadeg"
echo ""

pg_dump --file data/osm_roads.sql --host $HOST_DB_osm --username osmbr --no-password \
--format=p --no-owner --section=pre-data --section=data --no-privileges --no-tablespaces --no-unlogged-table-data --no-comments \
--table public.osm_roads osm

# 5. import dans la base redadeg
psql -h $HOST_DB_redadeg -U redadeg -d redadeg -c "DROP TABLE IF EXISTS public.osm_roads;"
psql -h $HOST_DB_redadeg -U redadeg -d redadeg < data/osm_roads.sql

echo ""
echo "fait"
echo ""

echo "fini"

