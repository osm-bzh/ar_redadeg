#! /bin/bash

# exit dès que qqch se passe mal
set -e
# sortir si "unbound variable"
#set -u



# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


remove_file_if_exists () {

  local file_path="$1"

  if [ -f "$file_path" ]; then
      # echo "File exists and is a regular file."
      rm -f file_path
  # else
  #     echo "File does not exist or is not a regular file."
  fi

}


# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++




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

# traitement des tracés manuels

# on commence par supprimer la table
$PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "DROP TABLE IF EXISTS phase_1_trace_3857 CASCADE;"
# $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "DROP TABLE IF EXISTS phase_1_pk_vip_3857;"
echo ""


# on va lire le fichier de config des couches umap pour boucler
IFS="="
while read -r line
do
  IFS='/'
  read -ra ITEM <<<"$line"
  umap_map=${ITEM[0]}
  umap_layer=${ITEM[1]}

  url_umap="https://umap.openstreetmap.fr/fr/datalayer/${umap_map}/${umap_layer}/"
  dest_file="${rep_data}/import/phase_1_umap_trace_${umap_layer}.geojson"
  wget_command="wget -q -O \"$dest_file\" \"$url_umap\""

  echo "  umap layer id = $umap_layer"
  # echo "$wget_command"
  eval "$wget_command"
  echo "  recup ok"

  # on charge dans postgis
  # note : les coordonnées sont en 3857 mais la déclaration de la table = 4326

  ogr2ogr_command="ogr2ogr -f \"PostgreSQL\" \
  PG:\"host=$DB_HOST port=$DB_PORT user=$DB_USER password=$DB_PASSWD dbname=$DB_NAME\" \
  $dest_file -nln phase_1_trace_3857 -lco GEOMETRY_NAME=the_geom -explodecollections"

  echo "  chargement dans la couche d'import"
  # echo "$ogr2ogr_command"
  eval "$ogr2ogr_command"
  echo "  fait"
  echo ""

# fin de la boucle de lecture des layers umap
done < $rep_data/umap_phase_1_layers.txt


# PK VIP
# plus besoin depuis 2021 
#ogr2ogr -f "PostgreSQL" PG:"host=$DB_HOST user=$DB_USER password=$DB_PASSWD dbname=$DB_NAME" data/phase_1_umap_pk_vip.geojson -nln phase_1_pk_vip_3857 -lco GEOMETRY_NAME=the_geom -explodecollections -overwrite



echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Application des traitements SQL "
echo ""

# on crée les tables en 3948
psql_command="$PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f sql/phase_1_trace.sql"
# echo $psql_command
eval "$psql_command"
echo "  fait"
echo ""


echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Exports "
echo ""

echo "  exports geojson"
echo ""

# et on exporte vers Geojson
# les fichiers sont ensuite tout de suite visible dans umap


remove_file_if_exists "$rep_data/export/phase_1_trace_4326.geojson"
ogr2ogr_command="ogr2ogr -f \"GeoJSON\" $rep_data/export/phase_1_trace_4326.geojson \
PG:\"host=$DB_HOST port=$DB_PORT user=$DB_USER password=$DB_PASSWD dbname=$DB_NAME\" phase_1_trace_4326"
eval "$ogr2ogr_command"

# plus besoin des PK auto depuis 2022
# rm -f $rep_data/export/phase_1_pk_auto.geojson
# ogr2ogr -f "GeoJSON" $rep_data/export/phase_1_pk_auto.geojson PG:"host=$DB_HOST port=$DB_PORT user=$DB_USER password=$DB_PASSWD dbname=$DB_NAME" phase_1_pk_auto_4326
# rm -f $rep_data/export/phase_1_pk_auto.xlsx
# ogr2ogr -f "XLSX" $rep_data/export/phase_1_pk_auto.xlsx PG:"host=$DB_HOST port=$DB_PORT user=$DB_USER password=$DB_PASSWD dbname=$DB_NAME" phase_1_pk_auto_4326

echo "  fait"
echo ""

echo ""
echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  F I N traitements phase 1"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
