#!/bin/sh

cd /data/www/vhosts/ar-redadeg_openstreetmap_bzh/htdocs/scripts/

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# on récupère les couches geojson depuis umap

# les couches PK
# PK début - fin de secteur
curl -sS  http://umap.openstreetmap.fr/fr/datalayer/817220/ > data/phase_2_umap_pk_secteur.geojson
# PK techniques
curl -sS  http://umap.openstreetmap.fr/fr/datalayer/817221/ > data/phase_2_umap_pk_technique.geojson
# PK manuels
curl -sS  http://umap.openstreetmap.fr/fr/datalayer/817222/ > data/phase_2_umap_pk_manuel.geojson


# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# on les charge dans postgis
# après avoir supprimé les tables

# note : les coordonnées sont en 3857 mais la déclaration de la table = 4326

psql -U redadeg -d redadeg -c "DROP TABLE phase_2_pk_secteur_3857 CASCADE;"
ogr2ogr -f "PostgreSQL" PG:"host=localhost user=redadeg password=redadeg dbname=redadeg" data/phase_2_umap_pk_secteur.geojson -nln phase_2_pk_secteur_3857 -lco GEOMETRY_NAME=the_geom -explodecollections -overwrite



# on crée les tables en 3948 et on fait bien d'autres choses :
psql -U redadeg -d redadeg < traitements_phase_2.1.sql



