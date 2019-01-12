#!/bin/sh

cd /data/www/vhosts/ar-redadeg/htdocs/scripts/backup/

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# on récupère les couches geojson depuis umap pour sauvegarde au cas où

# le tracé manuel
curl -sS  http://umap.openstreetmap.fr/fr/datalayer/715180/ > "$(date +%Y%m%d)_$(date +%H%M)_phase_1_trace.geojson"
# PK VIP
curl -sS  http://umap.openstreetmap.fr/fr/datalayer/715179/ > "$(date +%Y%m%d)_$(date +%H%M)_phase_1_pk_vip.geojson"

