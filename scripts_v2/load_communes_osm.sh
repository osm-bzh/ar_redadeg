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


cd $rep_data

echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Récupération des communes FR"
echo ""

echo "  téléchargement"
millesimeSHP=20210101
{
  wget -nc http://osm13.openstreetmap.fr/~cquest/openfla/export/communes-$millesimeSHP-shp.zip -O communes-$millesimeSHP-shp.zip
  unzip -oq communes-$millesimeSHP-shp.zip
} ||

echo "  fait"
echo ""
echo "  chargement en base"

ogr2ogr -f "PostgreSQL" PG:"host=$DB_HOST port=$DB_PORT user=$DB_USER password=$DB_PASSWD dbname=$DB_NAME" \
  communes-$millesimeSHP.shp -nln osm_communes_fr_4326 -lco GEOMETRY_NAME=the_geom -explodecollections -overwrite -where "substr(insee,0,2) IN ('22','29','35','44','56')"

# nettoyage
rm communes-$millesimeSHP.*

echo "  fait"
echo ""


echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Récupération des communes BR"
echo ""

echo "  téléchargement"
{
  wget -nc https://tile.openstreetmap.bzh/data/br/osm_br_municipalities.geojson
} ||

echo "  fait"
echo ""
echo "  chargement en base"

ogr2ogr -f "PostgreSQL" PG:"host=$DB_HOST port=$DB_PORT user=$DB_USER password=$DB_PASSWD dbname=$DB_NAME" \
  osm_br_municipalities.geojson -nln osm_communes_br_4326 -lco GEOMETRY_NAME=the_geom -overwrite

echo "  fait"
echo ""


echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Chargement de la couche osm_communes"
echo ""

PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c \
"TRUNCATE TABLE osm_communes ;"

PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c \
"WITH comm_multi AS (
SELECT
  fr.insee,
  fr.nom,
  ST_Multi(ST_Union(fr.the_geom)) AS the_geom 
FROM osm_communes_fr_4326 fr
GROUP BY fr.insee, fr.nom
)
INSERT INTO osm_communes 
SELECT
  fr.insee,
  fr.nom AS name_fr, 
  br.name_br,
  ST_Transform(fr.the_geom,2154)
FROM comm_multi fr, osm_communes_br_4326 br
WHERE ST_Intersects(br.the_geom,fr.the_geom) AND fr.nom = br.name 
ORDER BY fr.insee ;"

PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c \
"VACUUM FULL osm_communes ;"

echo "  fait"
echo ""

echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  F I N "


