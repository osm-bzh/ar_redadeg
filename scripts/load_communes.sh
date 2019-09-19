#!/bin/sh

# ce script récupère une couche des communes de France et la charge dans la base de données

# récupérer la couche communales OSM
# https://www.data.gouv.fr/fr/datasets/decoupage-administratif-communal-francais-issu-d-openstreetmap/
wget http://osm13.openstreetmap.fr/~cquest/openfla/export/communes-20190101-shp.zip

mv communes-20190101-shp.zip data/
unzip communes-20190101-shp.zip


# tansformer le shape en requête insert
shp2pgsql -I communes-20190101.shp osm_communes > osm_communes.sql

# charger
psql -d redadeg -U redadeg -W < osm_communes.sql

# passer la couche de WGS84 en Lambert93
psql -c "INSERT INTO osm_communes
  SELECT
    gid,
    insee,
    nom,
    wikipedia,
  surf_ha,
    ST_Transform(ST_SetSRID(geom,4326),2154) AS the_geom
  FROM osm_communes_4326
  ORDER BY insee ASC ;"


# /!\ penser à ne garder que les communes nécessaires pour des questions de performance

