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


echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  PK secteurs"
echo ""

# récupération de l'id dans le fichier de configuration
umap_datalayer=$(sed '1!d' $rep_data/umap_phase_2_layers.txt)
IFS='/'
read -ra ITEM <<<"$umap_datalayer"
umap_map=${ITEM[0]}
umap_layer=${ITEM[1]}
IFS=""

# on commence par supprimer la table
$PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "DROP TABLE IF EXISTS phase_2_pk_secteur_3857 CASCADE;"
echo ""


echo "  récupération des fichiers geojson depuis la carte umap"
curl -sSk  https://umap.openstreetmap.fr/fr/datalayer/$umap_map/$umap_layer/ > $rep_data/import/phase_2_umap_pk_secteur.geojson
echo "  fait"
echo ""

# on charge dans postgis
# note : les coordonnées sont en 3857 mais la déclaration de la table = 4326

echo "  chargement dans la couche d'import"
ogr2ogr -f "PostgreSQL" PG:"host=$DB_HOST port=$DB_PORT user=$DB_USER password=$DB_PASSWD dbname=$DB_NAME" \
  $rep_data/import/phase_2_umap_pk_secteur.geojson -nln phase_2_pk_secteur_3857 -lco GEOMETRY_NAME=the_geom -explodecollections
echo "  fait"
echo ""




echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Points de nettoyage"
echo ""

# récupération de l'id dans le fichier de configuration
umap_datalayer=$(sed '2!d' $rep_data/umap_phase_2_layers.txt)
IFS='/'
read -ra ITEM <<<"$umap_datalayer"
umap_map=${ITEM[0]}
umap_layer=${ITEM[1]}
IFS=""

# on commence par supprimer la table
$PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "DROP TABLE IF EXISTS phase_2_point_nettoyage_3857 CASCADE;"
echo ""

echo "  récupération des fichiers geojson depuis la carte umap"
curl -sSk  https://umap.openstreetmap.fr/fr/datalayer/$umap_map/$umap_layer/ > $rep_data/import/phase_2_umap_points_nettoyage.geojson
echo "  fait"
echo ""

echo "  chargement dans la couche d'import"
ogr2ogr -f "PostgreSQL" PG:"host=$DB_HOST port=$DB_PORT user=$DB_USER password=$DB_PASSWD dbname=$DB_NAME" \
  $rep_data/import/phase_2_umap_points_nettoyage.geojson -nln phase_2_point_nettoyage_3857 -lco GEOMETRY_NAME=the_geom -explodecollections
echo "  fait"
echo ""


echo ""
echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  F I N récupération des données phase 2"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
