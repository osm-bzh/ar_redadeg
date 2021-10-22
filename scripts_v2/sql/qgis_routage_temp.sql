SELECT
  -1 AS secteur_id,
  -- info de routage
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
  CASE
  WHEN b.name_fr IS NULL AND b.ref IS NOT NULL THEN b.ref
ELSE b.name_fr
  END AS name_fr,
  CASE
  WHEN b.name_br IS NULL AND b.name_fr IS NULL AND b.ref IS NOT NULL THEN b.ref
WHEN b.name_br IS NULL AND b.name_fr IS NOT NULL THEN '# da dreiñ e brezhoneg #'
ELSE b.name_br
  END AS name_br,
  b.the_geom
FROM pgr_dijkstra(
    'SELECT id, source, target, cost, reverse_cost FROM osm_roads_pgr', 24335, 30631) as a
JOIN osm_roads_pgr b ON a.edge = b.id ;
