#!/bin/bash

set -e
set -u

PSQL=/usr/bin/psql
DB_HOST=localhost
DB_NAME=redadeg
DB_USER=redadeg


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

$PSQL -U $DB_USER -d $DB_NAME -c "DROP TABLE phase_2_pk_secteur_3857 CASCADE;"
ogr2ogr -f "PostgreSQL" PG:"host=localhost user=redadeg password=redadeg dbname=redadeg" data/phase_2_umap_pk_secteur.geojson -nln phase_2_pk_secteur_3857 -lco GEOMETRY_NAME=the_geom -explodecollections -overwrite


# on crée les tables en 3948 
# et bien d'autres choses :
# - recalage des PK secteurs sur un nœud du réseau routable
$PSQL -U $DB_USER -d $DB_NAME  < traitements_phase_2.1.sql




# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# ici on va calculer un itinéraire pour chaque secteur
# en utilisant les PK de début (ou fin) de chaque secteur

# https://www.manniwood.com/postgresql_and_bash_stuff/index.html


# on commence par vider la table qui contiendra les calculs d'itinéraires
$PSQL -h $DB_HOST -U $DB_USER -c "TRUNCATE TABLE phase_2_trace_pgr ;"


# on fait la requête qui va donner une liste de PK de secteurs
# et on calcule un itinéraire entre le PK de début et le PK suivant

$PSQL -X -h $DB_HOST -U $DB_USER $DB_NAME \
    -c "SELECT s.id, replace(s.nom_fr,' ','') AS nom_fr, replace(s.nom_br,' ','') AS nom_br, pk.pgr_node_id  
FROM phase_2_pk_secteur pk JOIN secteur s ON pk.id = s.id
ORDER BY pk.id ;" \
    --single-transaction \
    --set AUTOCOMMIT=off \
    --set ON_ERROR_STOP=on \
    --no-align \
    -t \
    --field-separator ' ' \
    --quiet | while read -a Record ; do

    # ici commence la boucle sur les PK de secteurs
    echo "----------------------------"
    
    #IFS="|"  pour forcer un délimiteur mais ne fonctionne pas : les espaces sont compris comme des séparateurs
    # alors la requête supprime les espaces. TODO

    # le premier PK = PK de début
    secteur_id=${Record[0]}
    secteur_nom_fr="${Record[1]}"
    secteur_nom_br="${Record[2]}"
    pk_id_start=${Record[3]}
    
    # maintenant il faut une 2e requête pour aller trouver le PK de fin
    # ce PK = le PK de début du secteur suivant
    read pk_id_end <<< $($PSQL -h $DB_HOST -U $DB_USER --no-align -t --quiet \
    -c "SELECT pgr_node_id FROM phase_2_pk_secteur WHERE id = $secteur_id + 1 ;")

    # on teste si on récupère qqch sinon ça veurt dire qu'on a pas de nœud de fin donc impossible de calculer un itinéraire
    if [[ -n "$pk_id_end" ]];
    then
        echo "calcul d'un itinéraire pour le secteur $secteur_nom_fr ($pk_id_start --> $pk_id_end)"

        $PSQL -h $DB_HOST -U $DB_USER -c \
    "INSERT INTO phase_2_trace_pgr
    SELECT
      $secteur_id AS secteur_id,
      -- info de routage
      a.path_seq,
      a.node,
      a.cost,
      a.agg_cost,
      -- infos OSM
      b.osm_id,
      b.highway,
      b.\"type\",
      b.oneway,
      b.ref,
      b.name_fr,
      b.name_br,
      b.the_geom
    FROM pgr_dijkstra(
        'SELECT id, source, target, cost, reverse_cost FROM osm_roads_pgr', $pk_id_start, $pk_id_end) as a
    JOIN osm_roads_pgr b ON a.edge = b.id ;"

        echo "fait"
    fi

    # fin de la boucle
    echo ""
    
done
