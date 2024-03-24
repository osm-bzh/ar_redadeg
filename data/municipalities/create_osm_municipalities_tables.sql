

-- SET search_path TO public;

-- la table des polygones des communes
DROP TABLE IF EXISTS osm_municipalities_polygon ;
CREATE TABLE osm_municipalities_polygon
(
   osm_id bigint
  ,"name" TEXT
  ,name_fr TEXT
  ,name_br TEXT
  ,city_code TEXT
  ,postal_code TEXT
  ,geom geometry
);
-- contraintes sur la géométrie
--ALTER TABLE osm_municipalities_polygon ADD CONSTRAINT osm_municipalities_polygon_pkey PRIMARY KEY (osm_id);
ALTER TABLE osm_municipalities_polygon ADD CONSTRAINT enforce_dims_geom  CHECK (st_ndims(geom) = 2);
ALTER TABLE osm_municipalities_polygon ADD CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(geom) = 'POLYGON'::text);
ALTER TABLE osm_municipalities_polygon ADD CONSTRAINT enforce_srid_the_geom CHECK (st_srid(geom) = 2154);
-- indexes
CREATE INDEX osm_municipalities_polygon_osm_id_idx ON osm_municipalities_polygon (osm_id);
CREATE INDEX osm_municipalities_polygon_geom_idx ON osm_municipalities_polygon USING gist (geom);
CREATE INDEX osm_municipalities_polygon_city_code_idx ON osm_municipalities_polygon (city_code);


-- la table des points des communes
DROP TABLE IF EXISTS osm_municipalities_point ;
CREATE TABLE osm_municipalities_point
(
   osm_id bigint
  ,"name" TEXT
  ,name_fr TEXT
  ,name_br TEXT
  ,city_code TEXT
  ,postal_code TEXT
  ,geom geometry
);
-- contraintes sur la géométrie
--ALTER TABLE osm_municipalities_point ADD CONSTRAINT osm_municipalities_point_pkey PRIMARY KEY (osm_id);
ALTER TABLE osm_municipalities_point ADD CONSTRAINT enforce_dims_geom  CHECK (st_ndims(geom) = 2);
ALTER TABLE osm_municipalities_point ADD CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(geom) = 'POINT'::text);
ALTER TABLE osm_municipalities_point ADD CONSTRAINT enforce_srid_the_geom CHECK (st_srid(geom) = 2154);
-- indexes
CREATE INDEX osm_municipalities_point_osm_id_idx ON osm_municipalities_point (osm_id);
CREATE INDEX osm_municipalities_point_geom_idx ON osm_municipalities_point USING gist (geom);
CREATE INDEX osm_municipalities_point_city_code_idx ON osm_municipalities_point (city_code);


