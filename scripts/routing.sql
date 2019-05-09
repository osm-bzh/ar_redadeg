
/*
==========================================================================

    phase 2 : préparation pour le calcul d'itinéraires en appui du réseau routier OSM

==========================================================================
*/

-- dans la base redadeg on a chargé la couche osm_roads qui a été calculée
-- à partir de données OSM

-- on efface la topologie existante
SELECT DropTopology('osm_roads_topo') ;

-- 1. création d'un schéma qui va accueillir le réseau topologique de la couche osm_roads
SELECT topology.CreateTopology('osm_roads_topo', 2154);

-- 2. ajout d'un nouvel attribut sur la table osm_roads
SELECT topology.AddTopoGeometryColumn('osm_roads_topo', 'public', 'osm_roads', 'topo_geom', 'LINESTRING');


-- on a donc un nouveau schéma osm_roads_topo qui contient 4 tables : edge_data, face, node, relation
-- et un nouvel enregistrement dans la table topology.layer
-- logiquement : c'est  1
SELECT layer_id FROM topology.layer WHERE table_name = 'osm_roads' ;


-- 3. on calcule le graphe topologique
-- en remplissant le nouvel attribut géométrique
-- le 1er chiffre est l'identifiant du layer dans la table topology.layer
-- le 2e chiffre est la tolérance en mètres
UPDATE osm_roads SET topo_geom = topology.toTopoGeom(the_geom, 'osm_roads_topo', 1, 0.00001);

/*
DO $$DECLARE r record;
BEGIN
  FOR r IN SELECT * FROM osm_roads LOOP
    BEGIN
      UPDATE osm_roads SET topo_geom = topology.toTopoGeom(the_geom, 'osm_roads_topo', 1, 0.01);
    EXCEPTION
      WHEN OTHERS THEN
        RAISE WARNING 'Loading of record % failed: %', r.id, SQLERRM;
    END;
  END LOOP;
END$$;
*/

-- à ce stade on a un graphe topolgique dans le schema osm_roads_topo


-- 4. remplissage de la couche routable depuis la couche d'origine et la topologie
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

-- vérification
SELECT pgr_analyzegraph('osm_roads_pgr', 1.0);
SELECT pgr_nodeNetwork('osm_roads_pgr', 1.0);


-- il ne reste plus qu'à faire des calculs d'itinéraires
-- test de calcul de plus court chemin
SELECT * FROM pgr_dijkstra(
    'SELECT id, source, target, cost, reverse_cost FROM osm_roads_pgr',
    12872, 12810
); 

-- avec la géométrie
SELECT
  a.seq AS id,
  a.path_seq,
  a.node,
  a.cost,
  a.agg_cost,
  b.osm_id,
  b.highway,
  b.ref,
  b.name_fr,
  b.name_br,
  b.the_geom
FROM pgr_dijkstra(
    'SELECT id, source, target, cost, reverse_cost FROM osm_roads_pgr',
    12872, 12145) as a
JOIN osm_roads_pgr b
ON a.edge = b.id 



-- permissions
ALTER SCHEMA osm_roads_topo OWNER TO redadeg ;
ALTER TABLE osm_roads_topo.edge_data OWNER TO redadeg ;
ALTER TABLE osm_roads_topo.face OWNER TO redadeg ;
ALTER TABLE osm_roads_topo.node OWNER TO redadeg ;
ALTER TABLE osm_roads_topo.relation OWNER TO redadeg ;
ALTER VIEW osm_roads_topo.edge OWNER TO redadeg ;
ALTER SEQUENCE osm_roads_topo.layer_id_seq OWNER TO redadeg ;
ALTER SEQUENCE osm_roads_topo.topogeo_s_1 OWNER TO redadeg ;


