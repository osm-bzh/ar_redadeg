/*
==========================================================================

    phase 2 : création de différentes données à partir du tracé routé

==========================================================================
*/

-- on prend le tracé routé et on fait une version simple
-- 1 ligne par secteur
TRUNCATE TABLE phase_2_trace_secteur ;
WITH trace_ordered AS (
  SELECT secteur_id, the_geom
  FROM phase_2_trace_pgr
  ORDER BY secteur_id, path_seq
)
INSERT INTO phase_2_trace_secteur
  SELECT
    secteur_id, '', '', 0, 0,
    ST_CollectionExtract(ST_UNION(the_geom),2) AS the_geom
  FROM trace_ordered
  GROUP BY secteur_id
  ORDER BY secteur_id ;

-- mise à jour des attributs
UPDATE phase_2_trace_secteur a
SET 
  nom_fr = b.nom_fr,
  nom_br = b.nom_br,
  longueur = TRUNC( ST_Length(the_geom)::numeric , 0),
  longueur_km = TRUNC( ST_Length(the_geom)::numeric / 1000 , 1)
FROM secteur b WHERE a.secteur_id = b.id ;


/*
TRUNCATE phase_2_trace_troncons ;
INSERT INTO phase_2_trace_troncons
  SELECT 
  row_number() over() as uid,
  -- infos redadeg
  NULL AS secteur_id,
  NULL AS km,
  NULL AS km_reel,
  NULL AS longueur,
  -- infos OSM
  --t.osm_id, t.highway, t.type, t.oneway, t.ref, t.name_fr, t.name_br,
  ST_LineSubstring(the_geom, 1000.00*n/length,
  CASE
  WHEN 1000.00*(n+1) < length THEN 1000.00*(n+1)/length
  ELSE 1
  END) AS the_geom
  FROM
  (
    SELECT
    secteur_id,
    ST_LineMerge(the_geom)::geometry(MultiLineString,2154) AS the_geom,
    ST_Length(the_geom) AS length,
  ST_GeometryType(ST_LineMerge(the_geom)::geometry(MultiLineString,2154)) AS geom_type
    FROM phase_2_trace_secteur
    --WHERE secteur_id = 8
    --GROUP BY secteur_id
    -- ce tri est le plus important
    ORDER BY secteur_id ASC
  ) AS t
  CROSS JOIN generate_series(0,10000) AS n
  WHERE n*1000.00/length < 1
  ORDER BY t.secteur_id ;
*/

