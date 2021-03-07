

WITH ref AS (
  SELECT COUNT(pk_id) as ref FROM phase_5_pk_ref
  WHERE (secteur_id >= 10 and secteur_id < 20)
),
umap AS (
  SELECT COUNT(pk_id) as umap FROM phase_5_pk_umap
  WHERE (secteur_id >= 10 and secteur_id < 20)
)
SELECT
  *,
  CASE
    WHEN ref.ref < umap.umap THEN 'plus'
  WHEN ref.ref > umap.umap THEN 'moins'
  WHEN ref.ref = umap.umap THEN 'égalité'
  ELSE 'problème'
  END AS test
FROM ref, umap


-- test de géométrie import umap
SELECT secteur_id, pk_id, ST_geometrytype(the_geom) FROM phase_5_pk_umap
WHERE ST_geometrytype(the_geom) <> 'ST_Point' OR secteur_id IS NULL OR pk_id IS NULL ;



-- test de distance PK ref -> pk umap
SELECT
 --COUNT(*)
 r.pk_id,
 r.secteur_id,
 TRUNC(ST_Distance(ST_Transform(r.the_geom,2154), ST_Transform(u.the_geom,2154))::numeric,2) as distance
FROM phase_5_pk_ref r FULL JOIN phase_5_pk_umap u ON r.pk_id = u.pk_id 
WHERE 
  TRUNC(ST_Distance(ST_Transform(r.the_geom,2154), ST_Transform(u.the_geom,2154))::numeric,2) > 1
--ORDER BY r.secteur_id, r.pk_id
ORDER BY TRUNC(ST_Distance(ST_Transform(r.the_geom,2154), ST_Transform(u.the_geom,2154))::numeric,2) desc


WITH liste_pk_decales AS (
  SELECT
   r.pk_id,
   r.secteur_id,
   TRUNC(ST_Distance(ST_Transform(r.the_geom,2154), ST_Transform(u.the_geom,2154))::numeric,2) as distance
  FROM phase_5_pk_ref r FULL JOIN phase_5_pk_umap u ON r.pk_id = u.pk_id 
  WHERE TRUNC(ST_Distance(ST_Transform(r.the_geom,2154), ST_Transform(u.the_geom,2154))::numeric,2) > 1
)
SELECT '1' as tri, '> 1000' as distance, COUNT(*) FROM liste_pk_decales WHERE (distance >= 1000)
UNION SELECT '2' as tri,  '> 500' as distance, COUNT(*) FROM liste_pk_decales WHERE (distance >= 500 AND distance < 1000)
UNION SELECT '3' as tri, '> 100' as distance, COUNT(*) FROM liste_pk_decales WHERE (distance >= 100 AND distance < 500)
UNION SELECT '4' as tri, '> 10' as distance, COUNT(*) FROM liste_pk_decales WHERE (distance >= 10 AND distance < 100)
UNION SELECT '5' as tri, '< 10' as distance, COUNT(*) FROM liste_pk_decales WHERE (distance < 10)
ORDER BY tri ;




-- ligne entre les PK recalés et les PK références





-- recalage des PK umap sur le trace
WITH
pk_decales AS (
  SELECT
   r.pk_id,
   r.secteur_id,
   TRUNC(ST_Distance(r.the_geom, u.the_geom)::numeric,2) as distance,
   u.the_geom
  FROM phase_5_pk_ref r FULL JOIN phase_5_pk_umap u ON r.pk_id = u.pk_id 
  WHERE TRUNC(ST_Distance(r.the_geom, u.the_geom)::numeric,2) > 1
  AND r.secteur_id = 20
),
buffer_troncons AS (
  SELECT troncon_id, ST_BUFFER(the_geom, 5) as the_geom
  FROM phase_3_trace_troncons
  WHERE secteur_id = 20
)

SELECT
  pk.pk_id, pk.the_geom,
  ST_Distance(pk.the_geom, ST_ClosestPoint(trace.the_geom, pk.the_geom)) AS distance,
  ST_Snap(
    pk.the_geom,  -- le point d'origine à recaler
    ST_ClosestPoint(trace.the_geom, pk.the_geom), -- le point le plus près dans la couche de nœuds
    ST_Distance(pk.the_geom, ST_ClosestPoint(trace.the_geom, pk.the_geom))* 1.01 -- dans la distance de ce plus proche point
  ) AS the_geom
FROM pk_decales pk, phase_3_trace_troncons trace, buffer_troncons
WHERE ST_INTERSECTS(pk.the_geom, buffer_troncons.the_geom)
AND trace.secteur_id = 20





WITH
pk_decales AS (
  SELECT
   r.pk_id,
   r.secteur_id,
   TRUNC(ST_Distance(r.the_geom, u.the_geom)::numeric,2) as distance_pk_ref,
   u.the_geom
  FROM phase_5_pk_ref r FULL JOIN phase_5_pk_umap u ON r.pk_id = u.pk_id 
  WHERE TRUNC(ST_Distance(r.the_geom, u.the_geom)::numeric,2) > 1
),
trace AS (
  SELECT
  troncon_id,
  ST_LineMerge(the_geom) AS the_geom
  FROM phase_3_trace_troncons
  WHERE secteur_id = 60
)
-- il faut qu'on commence par limiter au tronçon le plus près du PK
SELECT
  pk.pk_id,
  pk.the_geom AS pk_point,
  trace.the_geom AS trace,
  
FROM pk_decales pk, trace
WHERE ST_INTERSECTS(trace.the_geom, ST_BUFFER(pk.the_geom,2) )





