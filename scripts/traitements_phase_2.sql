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
UPDATE osm_roads SET topo_geom = topology.toTopoGeom(the_geom, 'osm_roads_topo', 1, 1.0);
-- 18 min


-- à ce stade on a un graphe topologique dans le schema osm_roads_topo


-- 4. remplissage de la couche routable depuis la couche d'origine et la topologie
-- on commence par vider avant de remplir
TRUNCATE TABLE osm_roads_pgr ;
-- reset des séquences
ALTER SEQUENCE osm_roads_pgr_vertices_pgr_id_seq RESTART WITH 1;
ALTER SEQUENCE osm_roads_pgr_noded_id_seq RESTART WITH 1;

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
  e.geom as the_geom
FROM osm_roads_topo.edge e,
     osm_roads_topo.relation rel,
     osm_roads o
WHERE e.edge_id = rel.element_id
  AND rel.topogeo_id = (o.topo_geom).id
);


-- 5. calcul du graphe routier par pgRouting
SELECT pgr_createTopology('osm_roads_pgr', 1.0);
-- 35 s

-- vérification
SELECT pgr_analyzegraph('osm_roads_pgr', 1.0);
SELECT pgr_nodeNetwork('osm_roads_pgr', 1.0);


-- il ne reste plus qu'à faire des calculs d'itinéraires







