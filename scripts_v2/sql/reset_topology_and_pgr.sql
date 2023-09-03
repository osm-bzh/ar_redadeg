
SELECT topology.DropTopology('osm_roads_topo');

TRUNCATE TABLE osm_roads_pgr ;
TRUNCATE TABLE osm_roads_pgr_noded ;
TRUNCATE TABLE osm_roads_pgr_vertices_pgr ;
TRUNCATE TABLE osm_roads_import ;
TRUNCATE TABLE osm_roads ;

ALTER SEQUENCE osm_roads_pgr_id_seq RESTART WITH 1 ;
ALTER SEQUENCE osm_roads_pgr_noded_id_seq RESTART WITH 1 ;
ALTER SEQUENCE osm_roads_pgr_vertices_pgr_id_seq RESTART WITH 1 ;
ALTER SEQUENCE topology.topology_id_seq RESTART WITH 1 ;

SELECT topology.CreateTopology('osm_roads_topo', 2154);
SELECT topology.AddTopoGeometryColumn('osm_roads_topo', 'public', 'osm_roads', 'topo_geom', 'LINESTRING');

