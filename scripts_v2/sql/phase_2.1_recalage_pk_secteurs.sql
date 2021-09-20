
-- dans la base redadeg on a chargé des données provenant de umap
-- ces données sont en 3857. On va les passer en 2154 (Lambert 93).




-- ici on fait une grosse requête qui va recaler les PK secteurs sur les nœuds routables
-- ça insère les points de secteurs dans la table en 2154

TRUNCATE TABLE phase_2_pk_secteur ;

--  on fait une table de base qui contient les relations entre le point à recaler et les poins de référence
--  on limite à un buffer de 25
WITH candidates AS
(
SELECT
  pk_org.id AS pk_id,
  pk_org.name AS name,
  pk_org.secteur_id AS secteur_id,
  node.id AS node_id,
  ST_Distance(pk_org.the_geom, ST_ClosestPoint(node.the_geom, pk_org.the_geom)) AS distance,
  ST_Snap(
    pk_org.the_geom,  -- le point d'origine à recaler
    ST_ClosestPoint(node.the_geom, pk_org.the_geom), -- le point le plus près dans la couche de nœuds
    ST_Distance(pk_org.the_geom, ST_ClosestPoint(node.the_geom, pk_org.the_geom))* 1.01 -- dans la distance de ce plus proche point
  ) AS the_geom
FROM
  (SELECT ogc_fid::integer AS id, name, secteur_id, ST_Transform(the_geom,2154) AS the_geom FROM phase_2_pk_secteur_3857) AS pk_org,
  (SELECT id, the_geom FROM osm_roads_pgr_vertices_pgr) AS node
WHERE
ST_INTERSECTS(node.the_geom, ST_BUFFER(ST_Transform(pk_org.the_geom,2154) ,25) )
ORDER BY pk_org.id, ST_Distance(pk_org.the_geom, ST_ClosestPoint(node.the_geom, pk_org.the_geom))
)
-- à partir de cette table on va faire une jointure entre les PK org et les nœuds ramenés par la sous-requête
INSERT INTO phase_2_pk_secteur
SELECT 
  a.pk_id AS id,
  a.name,
  b.node_id AS pgr_node_id,
  a.secteur_id::integer,
  b.the_geom
FROM candidates a JOIN 
(
-- on fait une table qui ordonne les points d'accroche
SELECT 
  pk_id, node_id, 
  -- le rang va permettre de donner le rang de chaque rapprochement et d'en faire un critère
  row_number() over (partition by pk_id order by min(distance)) AS rang,
  min(distance) AS min_distance,
  the_geom
FROM candidates
GROUP BY pk_id, secteur_id, node_id, the_geom
) b ON a.pk_id = b.pk_id
WHERE b.rang = 1
GROUP BY a.pk_id, a.name, a.secteur_id, b.node_id, b.the_geom 
ORDER BY a.pk_id ;


# un peu de ménage
VACUUM FULL phase_2_pk_secteur ;


