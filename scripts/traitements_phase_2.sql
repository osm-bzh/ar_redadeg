/*
==========================================================================

    phase 2 : calcul d'itinéraires en appui du réseau routier OSM

==========================================================================
*/

-- dans la base redadeg on a chargé la couche osm_roads qui a été calculée
-- à partir de données OSM



-- 2. ajout d'un nouvel attribut sur la table osm_roads
-- normalement il existe déjà mais au cas où on a rechargé un nouveau réseau routier
SELECT topology.AddTopoGeometryColumn('osm_roads_topo', 'public', 'osm_roads', 'topo_geom', 'LINESTRING');


-- 3. on calcule le graphe topologique
-- en remplissant le nouvel attribut géométrique
-- le 1er chiffre est l'identifiant du layer dans la table topology.layer
-- le 2e chiffre est la tolérance en mètres
UPDATE osm_roads SET topo_geom = topology.toTopoGeom(the_geom, 'osm_roads_topo', 1, 0.00001);
-- 1.0 = 18 min
-- 0.00001 = 2 min

-- à ce stade on a un graphe topologique dans le schema osm_roads_topo


-- 4. remplissage de la couche routable depuis la couche d'origine et la topologie
-- on commence par vider avant de remplir
TRUNCATE TABLE osm_roads_pgr ;
--TRUNCATE TABLE osm_roads_pgr_noded ;
TRUNCATE TABLE osm_roads_pgr_vertices_pgr ;
-- reset des séquences
ALTER SEQUENCE osm_roads_pgr_vertices_pgr_id_seq RESTART WITH 1;
--ALTER SEQUENCE osm_roads_pgr_noded_id_seq RESTART WITH 1;

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


-- 5. calcul du graphe routier par pgRouting
SELECT pgr_createTopology('osm_roads_pgr', 1.0);
-- 35 s

-- vérification
SELECT pgr_analyzegraph('osm_roads_pgr', 1.0);
SELECT pgr_nodeNetwork('osm_roads_pgr', 1.0);


-- il ne reste plus qu'à faire des calculs d'itinéraires
-- on met le résultat dans une table
TRUNCATE TABLE phase_2_trace_pgr ;
INSERT INTO phase_2_trace_pgr
SELECT
  -- info de routage
  a.seq AS id,
  a.path_seq,
  a.node,
  a.cost,
  a.agg_cost,
  -- infos OSM
  b.osm_id,
  b.highway,
  b."type",
  b.oneway,
  b.ref,
  b.name_fr,
  b.name_br,
  b.the_geom
FROM pgr_dijkstra(
    'SELECT id, source, target, cost, reverse_cost FROM osm_roads_pgr',
    7632, 687) as a
JOIN osm_roads_pgr b ON a.edge = b.id ;






