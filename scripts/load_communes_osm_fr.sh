#!/bin/bash

set -e
set -u

PSQL=/usr/bin/psql
DB_HOST=localhost
DB_NAME=redadeg
DB_USER=redadeg
DB_PASSWD=redadeg

# ce script récupère une couche des communes de France et la charge dans la base de données

cd data

# récupérer la couche communales OSM
# https://www.data.gouv.fr/fr/datasets/decoupage-administratif-communal-francais-issu-d-openstreetmap/
curl -sS http://osm13.openstreetmap.fr/~cquest/openfla/export/communes-20200101-shp.zip > communes-20200101-shp.zip

unzip -o communes-20200101-shp.zip

ogr2ogr -f "PostgreSQL" PG:"host=$DB_HOST user=$DB_USER password=$DB_PASSWD dbname=$DB_NAME" communes-20200101.shp -nln osm_communes_4326 -lco GEOMETRY_NAME=the_geom -explodecollections -overwrite


# passer la couche de WGS84 en Lambert93
$PSQL -h $DB_HOST -U $DB_USER -d $DB_NAME -c "TRUNCATE TABLE osm_communes ;"
$PSQL -h $DB_HOST -U $DB_USER -d $DB_NAME -c "
INSERT INTO osm_communes
  SELECT
    ogc_fid,
    insee,
    nom,
    wikipedia,
    surf_ha,
    ST_Transform(ST_SetSRID(the_geom,4326),2154) AS the_geom
  FROM osm_communes_4326
  WHERE left(insee,2) IN ('22','29','35','44','56')
  ORDER BY insee ASC ;"
$PSQL -h $DB_HOST -U $DB_USER -d $DB_NAME -c "VACUUM FULL osm_communes;"


