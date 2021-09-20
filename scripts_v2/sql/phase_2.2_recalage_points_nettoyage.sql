
-- on recale également les points de nettoyage sur le tracé
TRUNCATE TABLE phase_2_point_nettoyage ;

WITH candidates AS
(
SELECT
  pt_org.ogc_fid AS pt_id,
  edge.id AS edge_id,
  ST_Distance(pt_org.the_geom, ST_ClosestPoint(edge.the_geom, pt_org.the_geom)) AS distance,
  ST_Snap(
    pt_org.the_geom,  -- le point d'origine à recaler
    ST_ClosestPoint(edge.the_geom, pt_org.the_geom), -- le point le plus près dans la couche de nœuds
    ST_Distance(pt_org.the_geom, ST_ClosestPoint(edge.the_geom, pt_org.the_geom))* 1.01 -- dans la distance de ce plus proche point
  ) AS the_geom
FROM
  (SELECT ogc_fid::integer, ST_Transform(the_geom,2154) AS the_geom FROM phase_2_point_nettoyage_3857) AS pt_org,
  (SELECT id, the_geom FROM osm_roads_pgr) AS edge
WHERE
ST_INTERSECTS(edge.the_geom, ST_BUFFER(ST_Transform(pt_org.the_geom,2154) ,2) )
ORDER BY pt_org.ogc_fid, ST_Distance(pt_org.the_geom, ST_ClosestPoint(edge.the_geom, pt_org.the_geom))
)
INSERT INTO phase_2_point_nettoyage
  SELECT
    nextval('phase_2_point_nettoyage_id_seq'::regclass),
    pt_id,
    edge_id,
    distance,
    the_geom
  FROM candidates ;

-- un peu de ménage
VACUUM FULL phase_2_point_nettoyage ;

