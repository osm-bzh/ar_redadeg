#!/bin/bash

# depuis le mac

cd data

# dump des tables de routage

#pg_dump --file osm_roads.sql --host localhost --port 5432 --username osmbr \
#--no-password --verbose --format=p --no-owner --section=pre-data --section=data --no-privileges --no-tablespaces --no-unlogged-table-data --no-comments \
#--table public.osm_roads osm

pg_dump --file osm_roads_pgr.sql --host 192.168.56.131 --port 5432 --username redadeg \
--no-password --verbose --format=p --no-owner --section=pre-data --section=data --no-privileges --no-tablespaces --no-unlogged-table-data --no-comments \
--table public.osm_roads_pgr redadeg

pg_dump --file osm_roads_pgr_noded.sql --host 192.168.56.131 --port 5432 --username redadeg \
--no-password --verbose --format=p --no-owner --section=pre-data --section=data --no-privileges --no-tablespaces --no-unlogged-table-data --no-comments \
--table public.osm_roads_pgr_noded redadeg

pg_dump --file osm_roads_pgr_vertices_pgr.sql --host 192.168.56.131 --port 5432 --username redadeg \
--no-password --verbose --format=p --no-owner --section=pre-data --section=data --no-privileges --no-tablespaces --no-unlogged-table-data --no-comments \
--table public.osm_roads_pgr_vertices_pgr redadeg


# on zippe
zip osm_roads_pgr.zip osm_roads_pgr.sql osm_roads_pgr_noded.sql osm_roads_pgr_vertices_pgr.sql

# on envoi sur le serveur
rsync -av --progress osm_roads_pgr.zip breizhpovh2:/data/www/vhosts/ar-redadeg_openstreetmap_bzh/htdocs/scripts/data/

# on envoie des commande pour maj les tables de routage
ssh breizhpovh2 "cd /data/www/vhosts/ar-redadeg_openstreetmap_bzh/htdocs/scripts/data/ ; \
unzip -f osm_roads_pgr.zip ; \
psql -U redadeg -d redadeg -c 'DROP TABLE osm_roads_pgr; DROP TABLE osm_roads_pgr_noded; DROP TABLE osm_roads_pgr_vertices_pgr;'
psql -U redadeg -d redadeg < osm_roads_pgr.sql ; \
psql -U redadeg -d redadeg < osm_roads_pgr_noded.sql ; \
psql -U redadeg -d redadeg < osm_roads_pgr_vertices_pgr.sql"

