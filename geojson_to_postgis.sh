#!/bin/sh


# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# on récupère les couches geojson depuis umap

# le tracé manuel
curl -sS  http://umap.openstreetmap.fr/fr/datalayer/715180/ > phase_1_trace.geojson
# PK VIP
curl -sS  http://umap.openstreetmap.fr/fr/datalayer/715179/ > phase_1_pk_vip.geojson


# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# on charge dans postgis
# après avoir supprimé les tables

# note : les coordonnées sont en 3857 maisla déclaration de la table = 4326

psql -U redadeg -d redadeg -c "DROP TABLE phase_1_trace_3857 CASCADE;" 
ogr2ogr -f "PostgreSQL" PG:"host=localhost user=redadeg password=redadeg dbname=redadeg" phase_1_trace.geojson -nln phase_1_trace_3857 -lco GEOMETRY_NAME=the_geom -explodecollections

psql -U redadeg -d redadeg -c "DROP TABLE phase_1_pk_vip_3857;" 
ogr2ogr -f "PostgreSQL" PG:"host=localhost user=redadeg password=redadeg dbname=redadeg" phase_1_pk_vip.geojson -nln phase_1_pk_vip_3857 -lco GEOMETRY_NAME=the_geom


# on crée les tables en 3948
psql -U redadeg -d redadeg < load_tables_3948.sql


# et on exporte vers Geojson
ogr2ogr -f "GeoJSON" phase_1_pk_auto.geojson PG:"host=localhost user=redadeg password=redadeg dbname=redadeg" phase_1_pk_auto_4326

# les fichiers sont ensuite tout de suite visible dans umap

