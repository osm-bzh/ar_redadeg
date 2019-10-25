#!/bin/bash

cd /data/www/vhosts/ar-redadeg_openstreetmap_bzh/htdocs/scripts/backup/
#cd backup/

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# on récupère les couches geojson depuis umap pour sauvegarde au cas où

# carte phase 1
# le tracé manuel
#curl -sS  http://umap.openstreetmap.fr/fr/datalayer/746021/ > "phase_1/$(date +%Y%m%d)_$(date +%H%M)_phase_1_trace.geojson"
# PK VIP
#curl -sS  http://umap.openstreetmap.fr/fr/datalayer/715179/ > "phase_1/$(date +%Y%m%d)_$(date +%H%M)_phase_1_pk_vip.geojson"


# carte phase 2
# PK secteur
#curl -sS  http://umap.openstreetmap.fr/fr/datalayer/817220/ > "phase_2/$(date +%Y%m%d)_$(date +%H%M)_phase_2_pk_secteur.geojson"
# PK technique / PK tecknikel
#curl -sS  http://umap.openstreetmap.fr/fr/datalayer/817221/ > "phase_2/$(date +%Y%m%d)_$(date +%H%M)_phase_2_pk_techniques.geojson"
# points coupe tracé
#curl -sS  http://umap.openstreetmap.fr/fr/datalayer/861810/ > "phase_2/$(date +%Y%m%d)_$(date +%H%M)_phase_2_points_coupe_trace.geoson"


# on remonte d'un niveau ceux cd 06h 13h et 18h

# si le nom du fichier matche le motif regexp
# on copie le fichier dans un autre répertoire

# for f in jour_courant/*.geojson
# do
#   #if [[ $f =~ [0-9]{8}_(0600|1300|1800)_* ]]
#   if [[ $f =~ [0-9]{8}_(1200)_* ]]
#   then cp $f ./
#   fi
# done


# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# cartes phase 5

# on sauvegarde les couches de PK gérés manuellement par secteurs
# secteur 1
curl -sS http://umap.openstreetmap.fr/fr/datalayer/1027042/ > "phase_5/phase_5_pk_secteur_01_$(date +%Y%m%d)_$(date +%H%M).geojson"
# secteur 2
curl -sS http://umap.openstreetmap.fr/fr/datalayer/1027081/ > "phase_5/phase_5_pk_secteur_02_$(date +%Y%m%d)_$(date +%H%M).geojson"
# secteur 3
curl -sS http://umap.openstreetmap.fr/fr/datalayer/1027101/ > "phase_5/phase_5_pk_secteur_03_$(date +%Y%m%d)_$(date +%H%M).geojson"
# secteur 4
curl -sS http://umap.openstreetmap.fr/fr/datalayer/1027104/ > "phase_5/phase_5_pk_secteur_04_$(date +%Y%m%d)_$(date +%H%M).geojson"
# secteur 5
curl -sS http://umap.openstreetmap.fr/fr/datalayer/1027107/ > "phase_5/phase_5_pk_secteur_05_$(date +%Y%m%d)_$(date +%H%M).geojson"
# secteur 6
curl -sS http://umap.openstreetmap.fr/fr/datalayer/1027110/ > "phase_5/phase_5_pk_secteur_06_$(date +%Y%m%d)_$(date +%H%M).geojson"
# secteur 7
curl -sS http://umap.openstreetmap.fr/fr/datalayer/1027114/ > "phase_5/phase_5_pk_secteur_07_$(date +%Y%m%d)_$(date +%H%M).geojson"
# secteur 8
curl -sS http://umap.openstreetmap.fr/fr/datalayer/1027117/ > "phase_5/phase_5_pk_secteur_08_$(date +%Y%m%d)_$(date +%H%M).geojson"
# secteur 9
curl -sS http://umap.openstreetmap.fr/fr/datalayer/1027120/ > "phase_5/phase_5_pk_secteur_09_$(date +%Y%m%d)_$(date +%H%M).geojson"
# secteur 10
curl -sS http://umap.openstreetmap.fr/fr/datalayer/1027123/ > "phase_5/phase_5_pk_secteur_10_$(date +%Y%m%d)_$(date +%H%M).geojson"


# la couche des PK assemblés
cp ../data/phase_5_pk.geojson "phase_5/phase_5_pk_$(date +%Y%m%d)_$(date +%H%M).geojson"




