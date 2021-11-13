

/*

https://postgis.net/docs/ST_AddMeasure.html
http://postgis.net/docs/ST_LocateAlong.html
https://qastack.fr/gis/115341/point-sampling-along-a-pole-wrapping-coastline-with-postgis
https://qastack.fr/gis/88196/how-can-i-transform-polylines-into-points-every-n-metres-in-postgis
https://www.ibm.com/docs/en/informix-servers/12.10?topic=functions-st-locatealong-function

*/


-- RAZ de la topologie pgRouting
TRUNCATE TABLE phase_3_troncons_pgr;
ALTER SEQUENCE phase_3_troncons_pgr_id_seq RESTART WITH 1;
VACUUM phase_3_troncons_pgr;

TRUNCATE TABLE phase_3_troncons_pgr_vertices_pgr;
ALTER SEQUENCE phase_3_troncons_pgr_vertices_pgr_id_seq RESTART WITH 1;
VACUUM phase_3_troncons_pgr_vertices_pgr;

-- RAZ de la couche de PK
TRUNCATE TABLE phase_3_pk ;
VACUUM phase_3_pk;



-- on supprime ce qui concerne le secteur
DELETE FROM phase_3_troncons_pgr WHERE secteur_id = 100 ;
INSERT INTO phase_3_troncons_pgr (secteur_id, path_seq, osm_id, highway, type, oneway, ref, name_fr, name_br, the_geom)
  SELECT
    secteur_id, path_seq, osm_id, highway, type, oneway, ref, name_fr, name_br, the_geom
  FROM phase_2_trace_pgr
WHERE secteur_id = 100 ;


-- calcul des coûts (longueur)
UPDATE phase_3_troncons_pgr 
SET
cost = trunc(st_length(the_geom)::numeric,2),
reverse_cost = trunc(st_length(the_geom)::numeric,2)
WHERE secteur_id = 100 ;

-- calcul de la topologie
SELECT pgr_createTopology('phase_3_troncons_pgr', 0.001, rows_where:='secteur_id=100', clean:=false);



-- calcul d'un point placé à 920 m sur une ligne de 1000 m
WITH linemeasure AS (
  WITH line AS (
  -- on récupère une ligne de 1000 m calculée par pgRouting
  SELECT ST_Union(the_geom) AS the_geom
  FROM pgr_drivingDistance('SELECT id, source, target, cost, reverse_cost FROM phase_3_troncons_pgr 
  WHERE SOURCE IS NOT NULL AND id > 0',
  9,1000) a
  JOIN phase_3_troncons_pgr b ON a.edge = b.id 
  )
SELECT
  ST_AddMeasure(the_geom,0,ST_length(the_geom)) AS the_geom
FROM line
)
SELECT
  ST_LocateAlong(the_geom,920) AS the_geom
FROM linemeasure;


-- calcul de points tous les 200 m
-- depuis une ligne calculée par pgRouting
WITH linemeasure AS (
  WITH line AS (
  -- on récupère une ligne de 1000 m calculée par pgRouting
  SELECT ST_Union(the_geom) AS the_geom
  FROM pgr_drivingDistance('SELECT id, source, target, cost, reverse_cost FROM phase_3_troncons_pgr 
  WHERE SOURCE IS NOT NULL AND id > 0',
  9,2000) a
  JOIN phase_3_troncons_pgr b ON a.edge = b.id 
  )
SELECT
  generate_series(0, (ST_Length(line.the_geom))::int, 200) AS i,
  ST_AddMeasure(the_geom,0,ST_length(the_geom)) AS the_geom
FROM line
)
SELECT
  i  
  ,(ST_Dump(ST_GeometryN(ST_LocateAlong(the_geom, i), 1))).geom AS geom
FROM linemeasure;


-- calcul de points tous les 920 m
-- depuis une ligne calculée par pgRouting
WITH linemeasure AS (
  WITH line AS (
  -- on récupère un itinéraire calculée par pgRouting
  SELECT ST_Union(the_geom) AS the_geom
  FROM pgr_dijkstra('SELECT id, source, target, cost, reverse_cost FROM phase_3_troncons_pgr',
  9,1506) a
  JOIN phase_3_troncons_pgr b ON a.edge = b.id 
  )
SELECT
  generate_series(0, (ST_Length(line.the_geom))::int, 920) AS i,
  ST_AddMeasure(the_geom,0,ST_length(the_geom)) AS the_geom
FROM line
)
INSERT INTO phase_3_pk (pk_id,length_real,length_total,the_geom)
SELECT
  ROW_NUMBER() OVER() + 11 AS pk
  ,920
  ,i AS longueur_cumulee
  ,(ST_Dump(ST_GeometryN(ST_LocateAlong(the_geom, i), 1))).geom AS the_geom
FROM linemeasure ;



