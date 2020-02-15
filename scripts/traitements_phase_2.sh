#!/bin/bash

set -e
set -u

PSQL=/usr/bin/psql
DB_HOST=localhost
DB_NAME=redadeg
DB_USER=redadeg
DB_PASSWD=redadeg


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
# couche de points de nettoyage
curl -sS  http://umap.openstreetmap.fr/fr/datalayer/861810/ > data/phase_2_umap_point_nettoyage.geojson

echo "  fait"
echo ""

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# on les charge dans postgis
# après avoir supprimé les tables

# note : les coordonnées sont en 3857 mais la déclaration de la table = 4326

echo "  chargement des fichiers dans la BD"
echo ""

echo "phase_2_pk_secteur_3857"
$PSQL -h $DB_HOST -U $DB_USER -d $DB_NAME -c "DROP TABLE IF EXISTS phase_2_pk_secteur_3857 CASCADE;"
ogr2ogr -f "PostgreSQL" PG:"host=localhost user=redadeg password=redadeg dbname=redadeg" data/phase_2_umap_pk_secteur.geojson -nln phase_2_pk_secteur_3857 -lco GEOMETRY_NAME=the_geom -explodecollections -overwrite

echo "phase_2_point_nettoyage_3857"
$PSQL -h $DB_HOST -U $DB_USER -d $DB_NAME -c "DROP TABLE IF EXISTS phase_2_point_nettoyage_3857 CASCADE;"
ogr2ogr -f "PostgreSQL" PG:"host=localhost user=redadeg password=redadeg dbname=redadeg" data/phase_2_umap_point_nettoyage.geojson -nln phase_2_point_nettoyage_3857 -lco GEOMETRY_NAME=the_geom -explodecollections -overwrite

echo "  fait"
echo ""

# on crée les tables en 3948 
# et bien d'autres choses :
# - recalage des PK secteurs sur un nœud du réseau routable
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Application des traitements SQL 2.1"
echo ""

$PSQL -h $DB_HOST -U $DB_USER -d $DB_NAME  < traitements_phase_2.1.sql

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
echo "vidage de la couche de routage"
$PSQL -h $DB_HOST -U $DB_USER -d $DB_NAME -c "TRUNCATE TABLE phase_2_trace_pgr ;"
echo "  fait"

# ensuite : on supprime les tronçons ciblés par la couche de points de nettoyage
# AVANT de calculer les itinéraires
echo "nettoyage de la couche de routage par les points ciblés"
$PSQL -h $DB_HOST -U $DB_USER -d $DB_NAME -c "UPDATE osm_roads_pgr SET cost = 1000000, reverse_cost = 1000000 WHERE id IN (SELECT r.id FROM osm_roads_pgr r JOIN phase_2_point_nettoyage p ON r.id = p.edge_id);"
echo "  fait"
echo ""


# on fait la requête qui va donner une liste de PK de secteurs
# et on calcule un itinéraire entre le PK de début et le PK suivant

# on va utiliser un compteur pour pouvoir sauter un sous-secteur à un autre
counter=1
# autre variables de contrôle
longueur_totale=0
longueur_inseree=0



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
    troncon_name=${Record[5]}

    echo "  $secteur_id | $secteur_nom_fr / $secteur_nom_br"
    echo "  tronçon : $troncon_name"
    echo "  PK ID = $pk_id"
    echo "  start node = $pk_id_start"

    # on fait une requête pour récupérer l'id du nœud de routage de fin
    # ce nœud = le PK de début du secteur suivant
    read pk_id_end <<< $($PSQL -h $DB_HOST -U $DB_USER --no-align -t --quiet \
      -c "SELECT pgr_node_id FROM phase_2_pk_secteur ORDER BY id OFFSET $counter LIMIT 1 ;" )

    echo "  end node = $pk_id_end"


    # on teste si on récupère qqch sinon ça veurt dire qu'on a pas de nœud de fin donc impossible de calculer un itinéraire
    if [[ -n "$pk_id_end" ]];
    then
        echo "  calcul de l'itinéraire"

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
        JOIN osm_roads_pgr b ON a.edge = b.id ;" >> /dev/null

        # on fait une requête pour voir la longueur insérée
        # en fait : la longueur totale - la longueur totale lors du précédent calcul
        read longueur_base <<< $($PSQL -h $DB_HOST -U $DB_USER --no-align -t --quiet \
          -c "SELECT trunc(SUM(ST_Length(the_geom))/1000) as longueur_totale FROM phase_2_trace_pgr ;" )
        longueur_inseree=$(($longueur_base-$longueur_totale))
        longueur_totale=$longueur_base
        
        # une alerte si 0 km insérés
        if [ $longueur_inseree -eq 0 ] ;
        then
          echo ""
          echo "    E R R E U R   !!!!!!!!"
          echo ""
        else
          echo "  fait : $longueur_inseree km (total = $longueur_totale km)"
        fi

    else
        echo ""
        echo "  E R R E U R   !!!!!!!!"
        echo "  impossible de calculer un itinéraire pour ce secteur"
        echo ""
    fi


    # fin de la boucle
    # on incrémente le compteur
    ((counter++))
    echo ""
    
done

echo "  Calcul des itinéraires terminé"
echo ""


# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#  on applique maintenant des requêtes SQL de création des données dérivées des données de routage


echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Application des traitements SQL 2.2"
echo ""

$PSQL -h $DB_HOST -U $DB_USER -d $DB_NAME < traitements_phase_2.2.sql




# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#  et on exporte en geojson pour umap

echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Exports et upload vers le serveur de diffusion"
echo ""

echo "  exports geojson"
echo ""

rm data/phase_2_pk_secteur.geojson
ogr2ogr -f "GeoJSON" data/phase_2_pk_secteur.geojson PG:"host=$DB_HOST user=$DB_USER password=$DB_PASSWD dbname=$DB_NAME" phase_2_pk_secteur_4326
rm data/phase_2_trace_pgr.geojson
ogr2ogr -f "GeoJSON" data/phase_2_trace_pgr.geojson PG:"host=$DB_HOST user=$DB_USER password=$DB_PASSWD dbname=$DB_NAME" phase_2_trace_pgr_4326
rm data/phase_2_trace_secteur.geojson
ogr2ogr -f "GeoJSON" data/phase_2_trace_secteur.geojson PG:"host=$DB_HOST user=$DB_USER password=$DB_PASSWD dbname=$DB_NAME" phase_2_trace_secteur_4326
# les fichiers sont ensuite tout de suite visible dans umap


# exports supplémentaires
echo "  exports supplémentaires"
echo ""

rm data/phase_2_tdb.xlsx
ogr2ogr -f "XLSX" data/phase_2_tdb.xlsx PG:"host=$DB_HOST user=$DB_USER password=$DB_PASSWD dbname=$DB_NAME" phase_2_tdb
rm data/phase_2_tdb.csv
ogr2ogr -f "CSV" data/phase_2_tdb.csv PG:"host=$DB_HOST user=$DB_USER password=$DB_PASSWD dbname=$DB_NAME" phase_2_tdb

echo "  fait"
echo ""
echo "  upload"
echo ""

# upload
rsync -av -z data/phase_2_pk_secteur.geojson data/phase_2_trace_pgr.geojson data/phase_2_trace_secteur.geojson data/phase_2_tdb.xlsx data/phase_2_tdb.csv breizhpovh2:/data/www/vhosts/ar-redadeg_openstreetmap_bzh/htdocs/scripts/data/

echo "  fait"
echo ""

echo ""
echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  F I N traitements phase 2"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
