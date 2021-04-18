#! /bin/bash

# exit dès que qqch se passe mal
set -e
# sortir si "unbound variable"
#set -u


if [ -z "$1" ]
  then
    echo "Pas de millésime en argument --> stop"
    exit 1
fi

# lecture du fichier de configuration
. config.sh

# ce script récupère une couche des communes de France et la charge dans la base de données

cd $rep_data

millesimeSHP=20210101

# récupérer la couche communales OSM
# https://www.data.gouv.fr/fr/datasets/decoupage-administratif-communal-francais-issu-d-openstreetmap/
wget http://osm13.openstreetmap.fr/~cquest/openfla/export/communes-$millesimeSHP-shp.zip -O communes-$millesimeSHP-shp.zip

unzip -o communes-$millesimeSHP-shp.zip

ogr2ogr -f "PostgreSQL" PG:"host=$DB_HOST user=$DB_USER password=$DB_PASSWD dbname=$DB_NAME" \
  communes-$millesimeSHP.shp -nln osm_communes_4326 -lco GEOMETRY_NAME=the_geom -explodecollections -overwrite


# passer la couche de WGS84 en Lambert93
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "TRUNCATE TABLE osm_communes ;"
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "
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
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "VACUUM FULL osm_communes;"

# nettoyage
rm communes-$millesimeSHP.*
