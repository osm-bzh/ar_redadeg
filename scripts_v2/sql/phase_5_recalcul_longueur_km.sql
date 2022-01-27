WITH pk AS (
  -- la liste des PK à traiter
  SELECT pk_id
  FROM phase_5_pk
  WHERE length_real = 0
  --AND pk_id BETWEEN 77 AND 81
),
pgr_vertices AS (
  -- une table avec les id des vertex du réseau routage les plus proches de tous les PK
  SELECT
    ROW_NUMBER() OVER(PARTITION BY pk.pk_id ORDER BY ST_Distance(pk.the_geom, v.the_geom) ASC) AS RANK 
    ,pk.pk_id
    ,v.id AS vertice_id
    ,ST_Distance(pk.the_geom, v.the_geom) AS distance
    --,pk.the_geom
  FROM phase_5_pk pk, phase_3_troncons_pgr_vertices_pgr v 
  WHERE 
    ST_DWithin(pk.the_geom, v.the_geom, 25)
  ORDER BY pk.pk_id, distance ASC
),
t_from AS (
  SELECT
    p.pk_id AS pk_from
    ,v.vertice_id AS v_from
    ,(p.pk_id+1) AS pk_to
  FROM pk p JOIN pgr_vertices v ON p.pk_id = v.pk_id
  WHERE v.RANK = 1
),
t_base AS (
  -- la table voulue avec les infos pour calculer un routage
  SELECT
    p.pk_from
    ,v_from
    ,p.pk_to
    ,v.vertice_id AS v_to
  FROM t_from p JOIN pgr_vertices v ON p.pk_to = v.pk_id
  WHERE v.RANK = 1
),
t_final AS (
  SELECT 
    t.pk_from
    ,t.pk_to
    ,(
      SELECT TRUNC(a.agg_cost::numeric,0)
      FROM pgr_dijkstraCost('SELECT id, source, target, cost, reverse_cost FROM phase_3_troncons_pgr WHERE source IS NOT NULL', t.v_from, t.v_to) AS a
    ) AS length_real 
  FROM t_base t
)
-- SELECT * FROM t_final
-- UPDATE final
UPDATE phase_5_pk o
SET length_real = t.length_real
FROM t_final t 
WHERE o.pk_id = t.pk_from ;

