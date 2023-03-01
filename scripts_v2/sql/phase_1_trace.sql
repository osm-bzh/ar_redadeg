

TRUNCATE phase_1_trace ;
INSERT INTO phase_1_trace
  SELECT
    ogc_fid,
    secteur_id::int,
    ordre::int,
    0 AS longueur,
    ST_Force2D(ST_Transform(the_geom,2154)) AS the_geom
  FROM phase_1_trace_3857
  WHERE ST_LENGTH(the_geom) > 0
  ORDER BY secteur_id ASC, ordre ASC ;

-- mise à jour de la longueur 1 fois la géométrie passée en CC48
UPDATE phase_1_trace
SET longueur = TRUNC( ST_Length(the_geom)::numeric / 1000 , 2) ;


-- on remplit la table trace 4326 pour exporter vers umap
TRUNCATE phase_1_trace_4326 ;
INSERT INTO phase_1_trace_4326
  SELECT
    t.ogc_fid,
    s.nom_br AS name,
    t.secteur_id::int,
    t.ordre::int,
    t.longueur,
    ST_Transform(t.the_geom,4326) AS the_geom
  FROM phase_1_trace t JOIN secteur s ON t.secteur_id = s.id
  ORDER BY secteur_id ASC, ordre ASC ;


TRUNCATE phase_1_trace_troncons ;
INSERT INTO phase_1_trace_troncons
  SELECT 
    row_number() over() as uid,
    secteur_id,
    ordre,
    NULL AS km,
    NULL AS km_reel,
    NULL AS longueur,
    ST_LineSubstring(the_geom, 1000.00*n/length,
    CASE
      WHEN 1000.00*(n+1) < length THEN 1000.00*(n+1)/length
      ELSE 1
    END) AS the_geom
  FROM
    (SELECT
       ogc_fid,
       secteur_id,
       ordre,
       ST_LineMerge(the_geom)::geometry(LineString,2154) AS the_geom,
       ST_Length(the_geom) As length
    FROM phase_1_trace
    -- ce tri est le plus important
    ORDER BY secteur_id ASC, ordre ASC
    ) AS t
  CROSS JOIN generate_series(0,10000) AS n
  WHERE n*1000.00/length < 1
  ORDER BY t.secteur_id ASC, t.ordre ASC ;

-- mise à jour des attributs
UPDATE phase_1_trace_troncons
SET 
  longueur = 
  (CASE
    WHEN TRUNC( ST_Length(the_geom)::numeric , 0)  = 999 THEN 1000
    ELSE TRUNC( ST_Length(the_geom)::numeric , 0)
  END),
  km = uid -- km redadeg
;

