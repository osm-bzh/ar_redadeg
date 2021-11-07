

-- permet de créer 1 seule ligne pour 1 secteur

DELETE FROM phase_3_trace_secteurs WHERE secteur_id = 100 ;
WITH t AS (
  SELECT *
  FROM phase_2_trace_troncons
  WHERE secteur_id = 100
)
INSERT INTO phase_3_trace_secteurs
SELECT
  secteur_id, s.nom_fr, s.nom_br,
  0 as km_reels,
  --ST_AsText(ST_LineMerge(ST_Collect(t.the_geom))) as txt_geom,
  ST_LineMerge(ST_Collect(t.the_geom)) as the_geom
FROM t JOIN secteur s ON t.secteur_id = s.id
GROUP BY t.secteur_id, s.nom_fr, s.nom_br ;

UPDATE phase_3_trace_secteurs
SET km_reels = TRUNC( ST_Length(the_geom)::numeric /1000 , 1)
WHERE secteur_id = 100 ;



--The below example simulates a while loop in
--SQL using PostgreSQL generate_series() to cut all
--linestrings in a table to 100 unit segments
-- of which no segment is longer than 100 units
-- units are measured in the SRID units of measurement
-- It also assumes all geometries are LINESTRING or contiguous MULTILINESTRING
--and no geometry is longer than 100 units*10000
--for better performance you can reduce the 10000
--to match max number of segments you expect

TRUNCATE phase_3_trace_troncons ;

INSERT INTO phase_3_trace_troncons
SELECT
  row_number() over(),
  secteur_id,
  ST_LineSubstring(the_geom, 1000.00*n/length,
  CASE
  WHEN 1000.00*(n+1) < length THEN 1000.00*(n+1)/length
  ELSE 1
  END) As the_geom
FROM
  (
  SELECT
    secteur_id,
    ST_Length(the_geom) AS length,
    ST_LineMerge(the_geom) AS the_geom
  FROM phase_3_trace_secteurs
  ) AS t
CROSS JOIN generate_series(0,10000) AS n
WHERE n*1000.00/length < 1;





-- la table qui va accueillir une couche support de calcul itinéraire phase 3
-- à savoir les tronçons phase 2 découpés tous les x mètres
DROP TABLE IF EXISTS phase_3_troncons_pgr CASCADE ;
CREATE TABLE phase_3_troncons_pgr
(
  secteur_id integer,
  -- info de routage
  id serial,
  source bigint,
  target bigint,
  cost double precision,
  reverse_cost double precision,
  -- info OSM
  osm_id bigint,
  highway text,
  type text,
  oneway text,
  ref text,
  name_fr text,
  name_br text,
  the_geom geometry,
  --CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'LINESTRING'::text),
  CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 2154)
);
CREATE INDEX phase_3_troncons_pgr_geom_idx ON phase_3_troncons_pgr USING gist(the_geom);
ALTER TABLE phase_3_troncons_pgr OWNER to redadeg;

-- on supprime les données pour le secteur
DELETE FROM phase_3_troncons_pgr WHERE secteur_id = $secteur_id ;

-- on charge, pour le secteur concerné des tronçons courts découpés tous les x mètres
-- (densification avec ST_LineSubstring )
INSERT INTO phase_3_troncons_pgr (secteur_id, osm_id, highway, type, oneway, ref, name_fr, name_br, the_geom)
 SELECT
  secteur_id, osm_id, highway, type, oneway, ref, name_fr, name_br,
  ST_LineSubstring(the_geom, $long_km_redadeg*n/length,
  CASE
  WHEN $long_km_redadeg*(n+1) < length THEN $long_km_redadeg*(n+1)/length
  ELSE 1
  END) As the_geom
FROM
  (
  SELECT
    secteur_id, osm_id, highway, type, oneway, ref, name_fr, name_br,
    ST_Length(the_geom) AS length,
    the_geom
  FROM phase_2_trace_troncons
  WHERE secteur_id = $secteur_id 
  ) AS t
CROSS JOIN generate_series(0,10000) AS n
WHERE n*$long_km_redadeg/length < 1;

-- calcul des attributs de support du calcul pour PGR
UPDATE phase_3_troncons_pgr 
SET cost = st_length(the_geom), reverse_cost = st_length(the_geom)
WHERE secteur_id = $secteur_id ; 

-- optimisation
VACUUM FULL phase_3_troncons_pgr ;

-- création / maj de la topologie pour les tronçons nouvellement créés
SELECT pgr_createTopology('phase_3_troncons_pgr', 0.001, rows_where:='true', clean:=true);




-------------


SELECT * 
FROM pgr_drivingDistance(
'SELECT id, source, target, cost, reverse_cost FROM phase_3_troncons_pgr WHERE SOURCE IS NOT NULL',
107, 300);




-- RAZ de la topologie pgRouting
TRUNCATE TABLE phase_3_troncons_pgr;
ALTER SEQUENCE phase_3_troncons_pgr_id_seq RESTART WITH 1;
VACUUM phase_3_troncons_pgr;

TRUNCATE TABLE phase_3_troncons_pgr_vertices_pgr;
ALTER SEQUENCE phase_3_troncons_pgr_vertices_pgr_id_seq RESTART WITH 1;
VACUUM phase_3_troncons_pgr_vertices_pgr;



