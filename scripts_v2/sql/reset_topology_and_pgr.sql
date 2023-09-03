
-- ces requêtes permettre de remettre totalement à zéro
-- les couches de routage et de topologie


-- phase 2

-- reset des couches pgRouting
TRUNCATE TABLE osm_roads_pgr ;
TRUNCATE TABLE osm_roads_pgr_noded ;
TRUNCATE TABLE osm_roads_pgr_vertices_pgr ;
ALTER SEQUENCE osm_roads_pgr_id_seq RESTART WITH 1 ;
ALTER SEQUENCE osm_roads_pgr_noded_id_seq RESTART WITH 1 ;
ALTER SEQUENCE osm_roads_pgr_vertices_pgr_id_seq RESTART WITH 1 ;

-- tables annexes
TRUNCATE TABLE osm_roads_import ;
TRUNCATE TABLE osm_roads ;

-- la topologie sur la couche osm roads
-- on la supprime
SELECT topology.DropTopology('osm_roads_topo');
ALTER SEQUENCE topology.topology_id_seq RESTART WITH 1 ;
-- puis on la recrée
SELECT topology.CreateTopology('osm_roads_topo', 2154);
SELECT topology.AddTopoGeometryColumn('osm_roads_topo', 'public', 'osm_roads', 'topo_geom', 'LINESTRING');


-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- phase 3
TRUNCATE TABLE public.phase_3_troncons_pgr ;
TRUNCATE TABLE public.phase_3_troncons_pgr_vertices_pgr ;
ALTER SEQUENCE public.phase_3_troncons_pgr_id_seq RESTART WITH 1 ;
ALTER SEQUENCE public.phase_3_troncons_pgr_vertices_pgr_id_seq RESTART WITH 1 ;

