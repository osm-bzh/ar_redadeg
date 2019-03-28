#!/bin/sh



# 1. export du tracé depuis la base redadeg

pg_dump --file data/redadeg_trace.sql --host localhost --username redadeg --no-password --format=p --no-owner --section=pre-data --section=data --no-privileges --no-tablespaces --no-unlogged-table-data --no-comments --table public.phase_1_trace redadeg



# 2. import dans la base OSM

psql -U osmbr -d osm -c "DROP TABLE public.phase_1_trace;"
psql -U osmbr -d osm < data/redadeg_trace.sql



# 3. calcul de la couche osm_roads = intersection buffer trace et routes OSM

psql -U osmbr -d osm -c "TRUNCATE TABLE osm_roads ;"
psql -U osmbr -d osm -c "WITH trace_buffer AS (
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



# 4. export de osm_roads depuis la base OSM

pg_dump --file data/osm_roads.sql --host localhost --username osmbr --no-password --format=p --no-owner --section=pre-data --section=data --no-privileges --no-tablespaces --no-unlogged-table-data --no-comments --table public.osm_roads osm



# 5. import dans la base redadeg

psql -U redadeg -d redadeg -c "DROP TABLE public.phase_1_trace;"
psql -U redadeg -d redadeg < data/redadeg_trace.sql

psql -U redadeg -d redadeg -c "TRUNCATE TABLE public.osm_roads;"
psql -U redadeg -d redadeg < data/osm_roads.sql


echo "fini"

