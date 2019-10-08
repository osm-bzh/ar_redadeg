#!/bin/bash

cd /data/www/vhosts/ar-redadeg_openstreetmap_bzh/htdocs/scripts/backup/

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# on récupère les couches geojson depuis umap pour sauvegarde au cas où

# carte phase 1
# le tracé manuel
curl -sS  http://umap.openstreetmap.fr/fr/datalayer/746021/ > "jour_courant/$(date +%Y%m%d)_$(date +%H%M)_phase_1_trace.geojson"
# PK VIP
curl -sS  http://umap.openstreetmap.fr/fr/datalayer/715179/ > "jour_courant/$(date +%Y%m%d)_$(date +%H%M)_phase_1_pk_vip.geojson"


#carte phase 2
# PK secteur
curl -sS  http://umap.openstreetmap.fr/fr/datalayer/817220/ > "jour_courant/$(date +%Y%m%d)_$(date +%H%M)_phase_2_pk_secteur.geojson"
# PK technique / PK tecknikel
curl -sS  http://umap.openstreetmap.fr/fr/datalayer/817221/ > "jour_courant/$(date +%Y%m%d)_$(date +%H%M)_phase_2_pk_techniques.geojson"
# points coupe tracé
curl -sS  http://umap.openstreetmap.fr/fr/datalayer/861810/ > "jour_courant/$(date +%Y%m%d)_$(date +%H%M)_phase_2_points_coupe_trace.geoson"



# et on remonte d'un niveau ceux cd 06h 13h et 18h

# si le nom du fichier matche le motif regexp
# on copie le fichier dans un autre répertoire

for f in jour_courant/*.geojson
do
  #if [[ $f =~ [0-9]{8}_(0600|1300|1800)_* ]]
  if [[ $f =~ [0-9]{8}_(1200)_* ]]
  then cp $f ./
  fi
done

