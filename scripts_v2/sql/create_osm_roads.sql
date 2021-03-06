/*
==========================================================================

    OpenStreetMap : création de la couche du réseau routier OSM
    pour le calcul d'itinéraires

==========================================================================
*/

--  A faire dans une base OSM contenant un import osm2pgsql

--  Le but est de créer une table osm_roads qui contiendra
--  le réseau routier dans une zone-tampon de 500 autour du tracé.

-- on fait ça dans une base à part à cause de la volumétrie des données OSM



-- 1. import du tracé dans la base OSM

-- export du tracé depuis la base redadeg
-- pg_dump --file redadeg_trace.sql --host localhost --username redadeg --no-password --format=p --no-owner --section=pre-data --section=data --no-privileges --no-tablespaces --no-unlogged-table-data --no-comments --table public.phase_1_trace redadeg

-- import dans la base osm
-- psql -U osmbr -d osm -c "DROP TABLE public.phase_1_trace;"
-- psql -U osmbr -d osm < redadeg_trace.sql




-- 2. création de la table qui va accueillir les tronçons de routes

-- la table qui contient le graphe routier de OSM
DROP TABLE IF EXISTS osm_roads ;
CREATE TABLE osm_roads
(
  uid bigint,
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
);



-- 3. remplissage de la table à l'aide d'un requête
-- qui va faire un buffer de 25 m autour du tracé
-- environ 5 min de traitement

TRUNCATE TABLE osm_roads ;
WITH trace_buffer AS (
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
) ;


-- 4. on l'exporte pour la recharger dans la base redadeg

-- commande d'export
-- pg_dump --file osm_roads.sql --host localhost --username osmbr --no-password --format=p --no-owner --section=pre-data --section=data --no-privileges --no-tablespaces --no-unlogged-table-data --no-comments --table public.osm_roads osm

-- commande d'import
-- psql -U redadeg -d redadeg -c "DROP TABLE public.osm_roads;"
-- psql -U redadeg -d redadeg < osm_roads.sql




