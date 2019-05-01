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

echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Récupération des fichiers geojson depuis umap"

# les couches PK
# PK début - fin de secteur
curl -sS  http://umap.openstreetmap.fr/fr/datalayer/817220/ > data/phase_2_umap_pk_secteur.geojson
# PK techniques
curl -sS  http://umap.openstreetmap.fr/fr/datalayer/817221/ > data/phase_2_umap_pk_technique.geojson
# PK manuels
curl -sS  http://umap.openstreetmap.fr/fr/datalayer/817222/ > data/phase_2_umap_pk_manuel.geojson


echo "  fait"
echo ""

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# on les charge dans postgis
# après avoir supprimé les tables

# note : les coordonnées sont en 3857 mais la déclaration de la table = 4326

echo "  chargement des fichiers dans la BD"

$PSQL -U $DB_USER -d $DB_NAME -c "DROP TABLE IF EXISTS phase_2_pk_secteur_3857 CASCADE;"
ogr2ogr -f "PostgreSQL" PG:"host=localhost user=redadeg password=redadeg dbname=redadeg" data/phase_2_umap_pk_secteur.geojson -nln phase_2_pk_secteur_3857 -lco GEOMETRY_NAME=the_geom -explodecollections -overwrite

echo "  fait"
echo ""

# on crée les tables en 3948 
# et bien d'autres choses :
# - recalage des PK secteurs sur un nœud du réseau routable
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Application des traitements SQL 2.1"
echo ""

$PSQL -U $DB_USER -d $DB_NAME  < traitements_phase_2.1.sql

echo "  fait"
echo ""



# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# ici on va calculer un itinéraire pour chaque secteur
# en utilisant les PK de début (ou fin) de chaque secteur

# https://www.manniwood.com/postgresql_and_bash_stuff/index.html

echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Calcul des itinéraires (pgrouting)"
echo ""

# on commence par vider la table qui contiendra les calculs d'itinéraires
$PSQL -h $DB_HOST -U $DB_USER -c "TRUNCATE TABLE phase_2_trace_pgr ;"


# on fait la requête qui va donner une liste de PK de secteurs
# et on calcule un itinéraire entre le PK de début et le PK suivant

$PSQL -X -h $DB_HOST -U $DB_USER $DB_NAME \
    -c "SELECT pk.id, s.id AS secteur_id, replace(s.nom_fr,' ','') AS nom_fr, replace(s.nom_br,' ','') AS nom_br, pk.pgr_node_id, replace(pk.name,' ','_') AS name 
FROM phase_2_pk_secteur pk JOIN secteur s ON pk.secteur_id = s.id
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
    pk_id=${Record[0]}
    secteur_id=${Record[1]}
    secteur_nom_fr="${Record[2]}"
    secteur_nom_br="${Record[3]}"
    pk_id_start=${Record[4]}
    pk_name=${Record[5]}
    
    # maintenant il faut une 2e requête pour aller trouver le PK de fin
    # ce PK = le PK de début du secteur suivant
    read pk_id_end <<< $($PSQL -h $DB_HOST -U $DB_USER --no-align -t --quiet \
    -c "SELECT pgr_node_id FROM phase_2_pk_secteur WHERE id = $pk_id + 1 ;")

    # on teste si on récupère qqch sinon ça veurt dire qu'on a pas de nœud de fin donc impossible de calculer un itinéraire
    if [[ -n "$pk_id_end" ]];
    then
        echo "calcul d'un itinéraire pour le secteur $pk_name / $secteur_nom_fr ($pk_id_start --> $pk_id_end)"

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
      CASE
      WHEN b.name_fr IS NULL AND b.ref IS NOT NULL THEN b.ref
    ELSE b.name_fr
      END AS name_fr,
      CASE
      WHEN b.name_br IS NULL AND b.name_fr IS NULL AND b.ref IS NOT NULL THEN b.ref
    WHEN b.name_br IS NULL AND b.name_fr IS NOT NULL THEN '# da dreiñ e brezhoneg #'
    ELSE b.name_br
      END AS name_br,
      b.the_geom
    FROM pgr_dijkstra(
        'SELECT id, source, target, cost, reverse_cost FROM osm_roads_pgr', $pk_id_start, $pk_id_end) as a
    JOIN osm_roads_pgr b ON a.edge = b.id ;"

        echo "fait"
    fi

    # fin de la boucle
    echo ""
    
done

echo "  Calcul des itinéraires terminé"
echo ""


# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#  on applique maintenant des requêtes SQL de création des données dérivées des données de routage


echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Application des traitements SQL 2.2"
echo ""

$PSQL -U $DB_USER -d $DB_NAME  < traitements_phase_2.2.sql




# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#  et on exporte en geojson pour umap

echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Exports"
echo ""

echo "  exports geojson"
echo ""

rm data/phase_2_pk_secteur.geojson
ogr2ogr -f "GeoJSON" data/phase_2_pk_secteur.geojson PG:"host=localhost user=redadeg password=redadeg dbname=redadeg" phase_2_pk_secteur_4326
rm data/phase_2_trace_pgr.geojson
ogr2ogr -f "GeoJSON" data/phase_2_trace_pgr.geojson PG:"host=localhost user=redadeg password=redadeg dbname=redadeg" phase_2_trace_pgr_4326
rm data/phase_2_trace_secteur.geojson
ogr2ogr -f "GeoJSON" data/phase_2_trace_secteur.geojson PG:"host=localhost user=redadeg password=redadeg dbname=redadeg" phase_2_trace_secteur_4326
# les fichiers sont ensuite tout de suite visible dans umap

echo "  fait"
echo ""

# on exporte un json de synthèse des KM par secteur
# TODO 


echo ""
echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  F I N"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
