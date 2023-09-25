#! /bin/bash



create_dump_breizh () {

  echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  echo "Téléchargement du dump France entière"
  echo ""

  date
  rm -f /data/dumps/france-latest.osm.pbf
  wget -O /data/dumps/france-latest.osm.pbf http://download.geofabrik.de/europe/france-latest.osm.pbf


  echo ""
  echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  echo ""
  echo " Decoupage dump France -> Breizh "
  echo ""

  date
  rm -f /data/dumps/breizh.osm.pbf
  # on le decoupe selon un polygone
  # utiliser JOSM avec le plugin poly pour créer un fichier .poly
  osmconvert /data/dumps/france-latest.osm.pbf -B=/data/dumps/poly_extraction_bzh.poly --complete-ways -v -o=/data/dumps/breizh.osm.pbf
  
}


update_db () {

  echo ""
  echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  echo ""
  echo " Mise à jour de la BD OSM "
  echo ""
  date
  echo ""

  # on met à jour la base de données
  # authentification dans le pgpass
  osm2pgsql -H db.openstreetmap.local -U osmbr -d osm \
  --hstore --slim --cache 3000 -E 3857 -v \
  /data/dumps/breizh.osm.pbf

  echo ""
  echo " Fin de la maj de la BD "
  date

}



# on teste si un dump de plus de 1 jour existe ou pas

file=/data/dumps/france-latest.osm.pbf

# Check if the file exists
if [ ! -e "$file" ]; then
    echo "Pas de dump"
    echo ""
    
    create_dump_breizh
    update_db

else
  
  # on a un fichier donc on calcule son âge pour savoir si on passe directement à la maj ou pas
  file_age=$(($(date +%s) - $(date -r "$file" +%s)))

  # Define the threshold for one day in seconds (24 hours * 60 minutes * 60 seconds)
  one_day=$((24 * 60 * 60))

  # Compare the file age to the one-day threshold
  if [ "$file_age" -gt "$one_day" ]; then
      
      #echo "Le dump est plus vieux que 1 jour"
      create_dump_breizh
      update_db

  else
      
      echo "Le dump est très récent donc on ne le met pas à jour"

      # Prompt the user for confirmation
      read -p "Voulez-vous mettre à jour la base quand même (o/n)? " answer

      # Check the user's response
      if [[ "$answer" =~ ^[Oo]$ ]]; then
          update_db
      else
          # on sort
          echo "F I N"
          exit 0
      fi

  fi

fi


echo ""
echo "F I N"
date
echo ""

