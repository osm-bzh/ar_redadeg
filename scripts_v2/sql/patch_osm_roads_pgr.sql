


-- suppression des objets couche osm_roads_pgr qui intersectent avec les zones de boucles
DELETE FROM osm_roads_pgr WHERE id IN
(
  SELECT a.id 
  FROM osm_roads_pgr a, osm_roads_pgr_patch_mask m
  WHERE ST_INTERSECTS(a.the_geom, m.the_geom)
);

-- collage des objets de la couche osm_roads_pgr_patch à la place des objets supprimés
-- on crée un identifiant négatif
INSERT INTO osm_roads_pgr
  SELECT
    0-a.id AS id,
    a.osm_id, a.highway, a.type, a.oneway, a.ref, a.name_fr, a.name_br,
    NULL, NULL, NULL, NULL,
    a.the_geom
  FROM osm_roads_pgr_patch a, osm_roads_pgr_patch_mask m
  WHERE ST_INTERSECTS(a.the_geom, m.the_geom);


-- calcul des 2 attributs de coût (= longueur)
UPDATE osm_roads_pgr 
SET cost = st_length(the_geom), reverse_cost = st_length(the_geom)
WHERE id < 0 ;


-- recrée des nœuds uniquement sur les zones de patch
SELECT pgr_nodeNetwork('osm_roads_pgr', 0.001, rows_where := 'id < 0');

-- recalcul la topologie pgRouting uniquement sur les zones de patch
SELECT pgr_createTopology('osm_roads_pgr', 0.001, rows_where := 'id < 0', clean := false);


-- recalcul toute la topologie pgRouting en renumérotant de zéro
--SELECT pgr_createTopology('osm_roads_pgr', 0.001, clean := true);

--SELECT pgr_analyzegraph('osm_roads_pgr', 0.001);
