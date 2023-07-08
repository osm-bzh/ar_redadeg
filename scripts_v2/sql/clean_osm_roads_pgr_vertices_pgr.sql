-- supprime tous les points de la couche osm_roads_pgr_vertices_pgr
-- qui ne sont pas concernés par la couche osm_roads_pgr
-- et donc orphelins et inutiles
DELETE FROM public.osm_roads_pgr_vertices_pgr
WHERE 
  id NOT IN (SELECT "source" FROM public.osm_roads_pgr)
  OR id NOT IN (SELECT target FROM public.osm_roads_pgr)
;
-- on renode derrière quand même
SELECT pgr_nodeNetwork('osm_roads_pgr', 0.001);
