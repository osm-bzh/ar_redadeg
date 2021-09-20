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
echo "  Récupération des fichiers geojson depuis umap"
echo ""


# on commence par supprimer la table
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "DROP TABLE IF EXISTS phase_2_pk_secteur_3857 CASCADE;"
echo ""


# on va lire le fichier de config des couches umap pour boucler
IFS="="
while read -r line
do
  layer=$line

  echo "  umap layer id = $layer"
  wget -q -O $rep_data/phase_2_umap_pk_secteur_$layer.geojson  https://umap.openstreetmap.fr/fr/datalayer/$layer
  echo "  recup ok"

  # on charge dans postgis
  # note : les coordonnées sont en 3857 mais la déclaration de la table = 4326

  echo "  chargement dans la couche d'import"
  ogr2ogr -f "PostgreSQL" PG:"host=$DB_HOST port=$DB_PORT user=$DB_USER password=$DB_PASSWD dbname=$DB_NAME" \
    $rep_data/phase_2_umap_pk_secteur_$layer.geojson -nln phase_2_pk_secteur_3857 -lco GEOMETRY_NAME=the_geom -explodecollections
  echo "  fait"
  echo ""


# fin de la boucle de lecture des layers umap
done < $rep_data/umap_phase_2_layers.txt


echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Application des traitements SQL"
echo ""

echo "  recalage des PK secteurs sur un nœud du réseau routable"
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME < sql/phase_2.1_recalage_pk_secteurs.sql
echo "  fait"
echo ""



echo ""
echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  F I N traitements phase 2"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
