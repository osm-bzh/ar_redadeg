/*
==========================================================================

    phase 2 : Mise à jour des couches de routage

==========================================================================
*/

-- /!\
-- cela suppose que la couche osm_roads est à jour !!
-- or cette couche est calculée à partir d'une BD osm cf la documentation


-- maj de la couche support des calculs d'itinéraire
-- 30 s
-- on commence par vider les couches existantes
TRUNCATE TABLE osm_roads_pgr ;
DROP TABLE IF EXISTS osm_roads_pgr_noded ;
DROP TABLE IF EXISTS  osm_roads_pgr_vertices_pgr ;


-- reset de la sequence
ALTER SEQUENCE public.osm_roads_pgr_noded_id_seq RESTART WITH 1 ;

-- on remplit la couche de lignes
INSERT INTO osm_roads_pgr
( SELECT 
  row_number() over() as id,
  o.osm_id,
  o.highway,
  o.type,
  o.oneway,
  o.ref,
  o.name_fr,
  o.name_br,
  NULL as source,
  NULL as target,
  NULL as cost,
  NULL as reverse_cost,
  e.geom as the_geom
FROM osm_roads_topo.edge e,
     osm_roads_topo.relation rel,
     osm_roads o
WHERE e.edge_id = rel.element_id
  AND rel.topogeo_id = (o.topo_geom).id
);

-- calcul des 2 attributs de coût (= longueur)
UPDATE osm_roads_pgr SET cost = st_length(the_geom), reverse_cost = st_length(the_geom);


-- calcul du graphe routier par pgRouting
-- cela va remplir les tables osm_roads_pgr_noded et osm_roads_pgr_vertices_pgr
-- 30 s
SELECT pgr_createTopology('osm_roads_pgr', 0.001);

-- vérification
SELECT pgr_analyzegraph('osm_roads_pgr', 0.001);
SELECT pgr_nodeNetwork('osm_roads_pgr', 0.001);



