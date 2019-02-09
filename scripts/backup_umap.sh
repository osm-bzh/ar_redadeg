#!/bin/bash

cd /data/www/vhosts/ar-redadeg_openstreetmap_bzh/htdocs/scripts/backup/

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# on récupère les couches geojson depuis umap pour sauvegarde au cas où

# le tracé manuel
curl -sS  http://umap.openstreetmap.fr/fr/datalayer/746021/ > "jour_courant/$(date +%Y%m%d)_$(date +%H%M)_phase_1_trace.geojson"
# PK VIP
curl -sS  http://umap.openstreetmap.fr/fr/datalayer/715179/ > "jour_courant/$(date +%Y%m%d)_$(date +%H%M)_phase_1_pk_vip.geojson"


# et on remonte d'un niveau ceux cd 06h 13h et 18h

# si le nom du fichier matche le motif regexp
# on copie le fichier dans un autre répertoire

for f in jour_courant/*.geojson
do
  if [[ $f =~ [0-9]{8}_(0600|1300|1800)_* ]]
  then cp $f ./
  fi
done

