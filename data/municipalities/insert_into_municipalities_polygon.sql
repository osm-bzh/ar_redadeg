
-- polygones des communes (un poil simplifié)
-- avec les informations
TRUNCATE TABLE osm_municipalities_polygon ;
INSERT INTO osm_municipalities_polygon 
  SELECT
    osm_id
    ,"name" AS "name"
    ,"name" AS name_fr
    ,COALESCE(tags -> 'name:br'::text,'') as name_br
    ,COALESCE(tags -> 'ref:INSEE'::text,'') as city_code
    ,COALESCE(tags -> 'postal_code'::text,'') as postal_code
    ,st_transform(ST_SetSRID(way, 3857), 2154) AS geom
  FROM planet_osm_polygon
  WHERE
    boundary = 'administrative'
    AND admin_level = '8'
;

DELETE FROM osm_municipalities_polygon
WHERE LEFT(city_code,2) NOT IN ('22','29','35','44','56') ;

VACUUM ANALYZE osm_municipalities_polygon ;


