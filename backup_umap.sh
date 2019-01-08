#!/bin/sh

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# on récupère les couches geojson depuis umap pour sauvegarde au cas où

# le tracé manuel
curl -sS  http://umap.openstreetmap.fr/fr/datalayer/715180/ > "backup/$(date +%Y%m%d)_$(date +%H%M)_phase_1_trace.geojson"
# PK VIP
curl -sS  http://umap.openstreetmap.fr/fr/datalayer/715179/ > "backup/$(date +%Y%m%d)_$(date +%H%M)_phase_1_pk_vip.geojson"

