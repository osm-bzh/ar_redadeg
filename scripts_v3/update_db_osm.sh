#! /bin/bash

# exit dès que qqch se passe mal
set -e

# répertoire avec les dumps
work_dir="/data/osm/dumps"




echo ""
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
echo " Mise à jour de la BD OSM "
echo ""
echo ""
date
echo ""



# Vérifier si le répertoire existe
if [ ! -d "$work_dir" ]; then
  # Créer le répertoire
  mkdir -p "$work_dir"
  echo "Le répertoire '$work_dir' a été créé."
  # on y copie le polygone d'extraction
  cp ../data/poly_extraction_bzh.poly $work_dir
else
  echo "Le répertoire '$work_dir' existe déjà."
fi

cd $work_dir

# on teste si un dump de plus de 1 jour existe ou pas

file=france-latest.osm.pbf

# Check if the file exists
if [ ! -e "$file" ]; then
  echo "Pas de dump France"
  echo ""
else
  echo "Un dump France existe…"

  # on a un fichier donc on calcule son âge pour savoir si on passe directement à la maj ou pas
  file_age=$(($(date +%s) - $(date -r "$file" +%s)))
  
  one_day=$((24 * 60 * 60))

  # Compare the file age to the one-day threshold
  if [ "$file_age" -gt "$one_day" ]; then
    echo "…mais il est trop ancien !"
    echo ""
    
    echo "Téléchargement du dump France entière"
    echo ""
    date
    rm -f france-latest.osm.pbf
    wget -O france-latest.osm.pbf http://download.geofabrik.de/europe/france-latest.osm.pbf
    date
    echo ""

    echo "Découpage du dump France entière"
    echo ""
    date
    rm -f breizh.osm.pbf
    # on le decoupe selon un polygone
    # utiliser JOSM avec le plugin poly pour créer un fichier .poly
    osmconvert france-latest.osm.pbf -B=poly_extraction_bzh.poly --complete-ways -v -o=breizh.osm.pbf
    date
    echo ""

    echo "Chargement de la base de données"
    echo ""
    date
    # authentification dans le pgpass
    osm2pgsql -H localhost -U redadeg -d osm --hstore --slim --cache 8000 -E 3857 -v breizh.osm.pbf
    date
    echo ""

  else
    echo "… et il est frais…"
    echo "… donc on s'arrête là.  "
  fi
fi



echo ""
echo "F I N"
date
echo ""

