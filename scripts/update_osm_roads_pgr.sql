/*
==========================================================================

    phase 2 : Mise à jour des couches de routage

==========================================================================
*/

-- /!\
-- cela suppose que la couche osm_roads est à jour !!
-- or cette couche est calculée à partir d'une BD osm cf la documentation


-- maj de la topologie de la couche osm_roads_pgr qui sert au routage
-- 3 min
UPDATE osm_roads SET topo_geom = topology.toTopoGeom(the_geom, 'osm_roads_topo', 1, 0.00001);


-- maj de la couche support des calculs d'itinéraire
-- 30 s
-- on commence par vider les couches existantes
TRUNCATE TABLE osm_roads_pgr ;
TRUNCATE TABLE osm_roads_pgr_noded ;
TRUNCATE TABLE osm_roads_pgr_vertices_pgr ;

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
UPDATE osm_roads_pgr SET cost = st_length(the_geom);
UPDATE osm_roads_pgr SET reverse_cost = st_length(the_geom);


-- calcul du graphe routier par pgRouting
-- cela va remplir les tables osm_roads_pgr_noded et osm_roads_pgr_vertices_pgr
-- 30 s
SELECT pgr_createTopology('osm_roads_pgr', 1.0);

-- vérification
SELECT pgr_analyzegraph('osm_roads_pgr', 1.0);
SELECT pgr_nodeNetwork('osm_roads_pgr', 1.0);


