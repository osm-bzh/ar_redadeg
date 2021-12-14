

-- on commence par supprimer les attributs, par sécurité
WITH pk_deplaces AS (
  -- table des PK déplacés
  SELECT
    r.pk_id
    ,ST_Distance(r.the_geom, u.the_geom) AS distance
    ,u.the_geom 
  FROM phase_5_pk_ref r FULL OUTER JOIN phase_5_pk_umap u ON r.pk_id = u.pk_id 
  WHERE TRUNC(ST_Distance(r.the_geom, u.the_geom)::numeric,2) > 1 
  ORDER BY r.pk_id 
)
UPDATE phase_5_pk ph5
SET (pk_x, pk_y, pk_long, pk_lat, length_real, length_theorical, length_total,
municipality_admincode, municipality_postcode, municipality_name_fr, municipality_name_br, 
way_osm_id, way_highway, way_type, way_oneway, way_ref, way_name_fr, way_name_br)
= (NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL)
FROM pk_deplaces
WHERE ph5.pk_id = pk_deplaces.pk_id



-- ici on fait une grosse requête qui va recaler les PK sur le tracé
-- et on insère dans la table UNIQUEMENT la géométrie
WITH pk_recales AS (
  WITH candidates AS (
    WITH pt AS (
      -- table des PK déplacés
      SELECT
        r.pk_id
        ,ST_Distance(r.the_geom, u.the_geom) AS distance
        ,u.the_geom 
      FROM phase_5_pk_ref r FULL OUTER JOIN phase_5_pk_umap u ON r.pk_id = u.pk_id 
      WHERE TRUNC(ST_Distance(r.the_geom, u.the_geom)::numeric,2) > 1 
      ORDER BY r.pk_id 
    )
    -- place un point projeté sur la ligne la plus proche
    SELECT
      ROW_NUMBER() OVER(PARTITION BY pt.pk_id ORDER BY pt.distance DESC) AS RANK,
      pt.pk_id,
      round(pt.distance) AS distance,
      ST_ClosestPoint(lines.the_geom, pt.the_geom) AS the_geom
    FROM pt, phase_2_trace_pgr lines
    WHERE ST_DWithin(pt.the_geom, lines.the_geom, 10)
  )
  SELECT 
    pk_id, distance, the_geom 
  FROM candidates
  WHERE RANK = 1
  ORDER BY pk_id
)
UPDATE phase_5_pk
SET the_geom = pk_recales.the_geom
FROM pk_recales
WHERE phase_5_pk.pk_id = pk_recales.pk_id ;


-- un peu de ménage
VACUUM FULL phase_5_pk ;


