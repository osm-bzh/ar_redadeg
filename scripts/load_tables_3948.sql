

TRUNCATE phase_1_trace_3948 ;
INSERT INTO phase_1_trace_3948
  SELECT
    ogc_fid, name,
    secteur::int,
    ordre::int,
    0,
    ST_Transform(the_geom,3948) AS the_geom
  FROM phase_1_trace_3857
  WHERE ST_LENGTH(the_geom) > 0
  ORDER BY secteur ASC, ordre ASC ;

-- mise à jour de la longueur 1 fois la géométrie passée en CC48
UPDATE phase_1_trace_3948
SET longueur = TRUNC( ST_Length(the_geom)::numeric / 1000 , 2) ;



TRUNCATE phase_1_pk_vip_3948 ;
INSERT INTO phase_1_pk_vip_3948
  SELECT ogc_fid, name, '', ST_Transform(the_geom,3948) AS the_geom
  FROM phase_1_pk_vip_3857 ;



TRUNCATE phase_1_trace_troncons_3948 ;
INSERT INTO phase_1_trace_troncons_3948
  SELECT 
      row_number() over() as uid,
      secteur,
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
       secteur,
       ordre,
       ST_LineMerge(the_geom)::geometry(LineString,3948) AS the_geom,
       ST_Length(the_geom) As length
    FROM phase_1_trace_3948
    -- ce tri est le plus important
    ORDER BY secteur ASC, ordre ASC
    ) AS t
  CROSS JOIN generate_series(0,10000) AS n
  WHERE n*1000.00/length < 1
  ORDER BY t.secteur ASC, t.ordre ASC ;

-- mise à jour des attributs
UPDATE phase_1_trace_troncons_3948
SET 
  longueur = 
  (CASE
    WHEN TRUNC( ST_Length(the_geom)::numeric , 0)  = 939 THEN 940
    ELSE TRUNC( ST_Length(the_geom)::numeric , 0)
  END),
  km = uid -- km redadeg

