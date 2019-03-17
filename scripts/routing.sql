
/*
==========================================================================

    phase 2 : préparation pour le calcul d'itinéraires en appui du réseau routier OSM

==========================================================================
*/

-- dans la base redadeg on a chargé la couche osm_roads qui a été calculée
-- à partir de données OSM


-- 1. création d'un schéma qui va accueillir le réseau topologique de la couche osm_roads
SELECT topology.CreateTopology('osm_roads_topo', 2154);

-- on a donc un nouveau schéma osm_roads_topo qui contient 4 tables : edge_data, face, node, relation
-- et un nouvel enregistrement dans la table topology.layer
-- logiquement : c'est  1
-- SELECT * FROM topology.layer ORDER BY layer_id desc ;


-- 2. ajout d'un nouvel attribut sur la table osm_roads
SELECT topology.AddTopoGeometryColumn('osm_roads_topo', 'public', 'osm_roads', 'topo_geom', 'LINESTRING');


-- 3. on calcule le graphe topologique
-- en remplissant le nouvel attribut géométrique
-- le 1er chiffre est l'identifiant du layer dans la table topology.layer
-- le 2e chiffre est la tolérance en mètres
UPDATE osm_roads SET topo_geom = topology.toTopoGeom(the_geom, 'osm_roads_topo', 1, 0.01);


-- à ce stade on a un graphe topolgique dans le schema osm_roads_topo


-- 4. remplissage de la couche routable depuis la couche d'origine et la topologie
INSERT INTO osm_roads_pgr
( SELECT 
  e.edge_id as id,
  o.osm_id,
  o.highway,
  o.type,
  o.oneway,
  o.ref,
  o.name_fr,
  o.name_br,
  o.source,
  o.target,
  e.geom as the_geom
FROM osm_roads_topo.edge e,
     osm_roads_topo.relation rel,
     osm_roads o
WHERE e.edge_id = rel.element_id
  AND rel.topogeo_id = (o.topo_geom).id
);


-- 5. calcul du graphe routier par pgRouting
SELECT pgr_createTopology('osm_roads_pgr', 1.0);

-- vérification
SELECT pgr_analyzegraph('osm_roads_pgr', 1.0);
SELECT pgr_nodeNetwork('osm_roads_pgr', 1.0);


-- il ne reste plus qu'à faire des calculs d'itinéraires
-- test de calcul de plus court chemin
SELECT * FROM pgr_dijkstra(
    'SELECT id, source, target, st_length(the_geom) as cost FROM osm_roads_pgr',
    6, 1
); 



-- si besoin : nettoyage par Drop du schéma
SELECT topology.DropTopology('osm_roads_topo');



