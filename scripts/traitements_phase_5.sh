#!/bin/bash

# ce traitement consiste à charger les données des 10 cartes umap
# à les contrôler par rapport aux données de référence
# à les agréger
# puis les exporter pour merour


set -e
set -u

#PSQL=/usr/bin/psql
PSQL=psql
DB_HOST=192.168.56.131
DB_NAME=redadeg
DB_USER=redadeg
DB_PASS=redadeg


#cd /data/www/vhosts/ar-redadeg_openstreetmap_bzh/htdocs/scripts/


echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Chargement des données des cartes umap"
echo ""
echo ""

  
  # OK !
  #dernierFichierCmd="ls -l1dt phase_5_pk_secteur_"$secteur"_* | head -1"
  #eval $dernierFichierCmd
  

# on procède secteur par secteur
# on récupère les données umap et on les charge dans la même couche

# on commence donc par vider la couche cible
# géré avec l'option -overwrite sur le secteur 1 -> pb : on a des lignes dans la couche de points…
# on commence par vider la table qui contiendra les calculs d'itinéraires

echo "  vidage de la couche de routage"
$PSQL -h $DB_HOST -U $DB_USER -d $DB_NAME -c "TRUNCATE TABLE phase_5_pk_umap_4326 ;"
echo "  fait"

echo ""
echo "  import des données umap"
echo ""

echo "    secteur 1"
curl -sS http://umap.openstreetmap.fr/fr/datalayer/1027042/ > data/phase_5_pk_umap_tmp.geojson
# chargement initial
ogr2ogr -f "PostgreSQL" PG:"host=$DB_HOST user=$DB_USER password=$DB_PASS dbname=$DB_NAME" \
data/phase_5_pk_umap_tmp.geojson -nln phase_5_pk_umap_4326 -explodecollections -append


echo "    secteur 2"
curl -sS http://umap.openstreetmap.fr/fr/datalayer/1027081/ > data/phase_5_pk_umap_tmp.geojson
# on rajoute à la couche
ogr2ogr -f "PostgreSQL" PG:"host=$DB_HOST user=$DB_USER password=$DB_PASS dbname=$DB_NAME" \
data/phase_5_pk_umap_tmp.geojson -nln phase_5_pk_umap_4326 -explodecollections -append


echo "    secteur 3"
curl -sS http://umap.openstreetmap.fr/fr/datalayer/1027101/ > data/phase_5_pk_umap_tmp.geojson
# on rajoute à la couche
ogr2ogr -f "PostgreSQL" PG:"host=$DB_HOST user=$DB_USER password=$DB_PASS dbname=$DB_NAME" \
data/phase_5_pk_umap_tmp.geojson -nln phase_5_pk_umap_4326 -explodecollections -append


echo "    secteur 4"
curl -sS http://umap.openstreetmap.fr/fr/datalayer/1027104/ > data/phase_5_pk_umap_tmp.geojson
# on rajoute à la couche
ogr2ogr -f "PostgreSQL" PG:"host=$DB_HOST user=$DB_USER password=$DB_PASS dbname=$DB_NAME" \
data/phase_5_pk_umap_tmp.geojson -nln phase_5_pk_umap_4326 -explodecollections -append


echo "    secteur 5"
curl -sS http://umap.openstreetmap.fr/fr/datalayer/1027107/ > data/phase_5_pk_umap_tmp.geojson
# on rajoute à la couche
ogr2ogr -f "PostgreSQL" PG:"host=$DB_HOST user=$DB_USER password=$DB_PASS dbname=$DB_NAME" \
data/phase_5_pk_umap_tmp.geojson -nln phase_5_pk_umap_4326 -explodecollections -append


echo "    secteur 6"
curl -sS http://umap.openstreetmap.fr/fr/datalayer/1027110/ > data/phase_5_pk_umap_tmp.geojson
# on rajoute à la couche
ogr2ogr -f "PostgreSQL" PG:"host=$DB_HOST user=$DB_USER password=$DB_PASS dbname=$DB_NAME" \
data/phase_5_pk_umap_tmp.geojson -nln phase_5_pk_umap_4326 -explodecollections -append


echo "    secteur 7"
curl -sS http://umap.openstreetmap.fr/fr/datalayer/1027114/ > data/phase_5_pk_umap_tmp.geojson
# on rajoute à la couche
ogr2ogr -f "PostgreSQL" PG:"host=$DB_HOST user=$DB_USER password=$DB_PASS dbname=$DB_NAME" \
data/phase_5_pk_umap_tmp.geojson -nln phase_5_pk_umap_4326 -explodecollections -append


echo "    secteur 8"
curl -sS http://umap.openstreetmap.fr/fr/datalayer/1027117/ > data/phase_5_pk_umap_tmp.geojson
# on rajoute à la couche
ogr2ogr -f "PostgreSQL" PG:"host=$DB_HOST user=$DB_USER password=$DB_PASS dbname=$DB_NAME" \
data/phase_5_pk_umap_tmp.geojson -nln phase_5_pk_umap_4326 -explodecollections -append


echo "    secteur 9"
curl -sS http://umap.openstreetmap.fr/fr/datalayer/1027120/ > data/phase_5_pk_umap_tmp.geojson
# on rajoute à la couche
ogr2ogr -f "PostgreSQL" PG:"host=$DB_HOST user=$DB_USER password=$DB_PASS dbname=$DB_NAME" \
data/phase_5_pk_umap_tmp.geojson -nln phase_5_pk_umap_4326 -explodecollections -append


echo "    secteur 10"
curl -sS http://umap.openstreetmap.fr/fr/datalayer/1027123/ > data/phase_5_pk_umap_tmp.geojson
# on rajoute à la couche
ogr2ogr -f "PostgreSQL" PG:"host=$DB_HOST user=$DB_USER password=$DB_PASS dbname=$DB_NAME" \
data/phase_5_pk_umap_tmp.geojson -nln phase_5_pk_umap_4326 -explodecollections -append



# ensuite on supprime les enregistrement aberrants
echo ""
echo "  suppression des données nulles"
$PSQL -h $DB_HOST -U $DB_USER -d $DB_NAME -c "DELETE FROM phase_5_pk_umap_4326 WHERE ST_geometrytype(the_geom) <> 'ST_Point' OR secteur_id IS NULL OR pk_id IS NULL ;"
echo "  fait"


# et on charge la couche en 2154 pour pouvoir travailler
echo ""
echo "  chargement de la couche de travail en 2154"
$PSQL -h $DB_HOST -U $DB_USER -d $DB_NAME \
-c "TRUNCATE phase_5_pk_umap ; 
INSERT INTO phase_5_pk_umap 
SELECT pk_id, secteur_id, ST_Transform(the_geom,2154) AS the_geom
FROM phase_5_pk_umap_4326
ORDER BY pk_id ;"
echo "  fait"


echo ""
echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Contrôle des données par secteur"
echo ""

# on veut la liste des vrais secteurs : pas des secteurs de gestion
# on instancie donc un tableau

declare -a secteursArray=()

secteursArray=(`$PSQL -h $DB_HOST -U $DB_USER $DB_NAME -t -X -A -c \
  "WITH a AS
    (
      SELECT substring(secteur_id::text,1, char_length(secteur_id::text)-1)::integer AS secteur_id
      FROM phase_5_pk_ref 
    )
    SELECT DISTINCT(secteur_id) FROM a ORDER BY secteur_id ;"`)

#echo "secteursArray = " ${secteursArray[@]}


# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo ""
echo "    1 : nombre de PK par secteur"
echo ""

for secteur in ${secteursArray[@]}
do
  #echo "      secteur $secteur"

  # une requête qui compare le nb de PK entre la couche de référence et la couche umap
  sect_deb=$secteur"0" # 1 --> 10
  sect_fin=$((secteur+1))0
  #echo "$sect_deb -> $sect_fin"

  $PSQL -X -A -t -h $DB_HOST -U $DB_USER $DB_NAME \
    -c "WITH ref AS (
        SELECT COUNT(pk_id) as ref FROM phase_5_pk_ref
        WHERE (secteur_id >= $sect_deb and secteur_id < $sect_fin)
      ),
      umap AS (
        SELECT COUNT(pk_id) as umap FROM phase_5_pk_umap
        WHERE (secteur_id >= $sect_deb and secteur_id < $sect_fin)
      )
      SELECT
        *,
        CASE
          WHEN ref.ref < umap.umap THEN 'plus'
        WHEN ref.ref > umap.umap THEN 'moins'
        WHEN ref.ref = umap.umap THEN 'pareil'
        ELSE 'problème'
        END AS test
      FROM ref, umap" \
    --single-transaction \
    --set AUTOCOMMIT=off \
    --set ON_ERROR_STOP=on \
    --no-align \
    -t \
    --field-separator ' ' \
    --quiet | while read -a Record ; do

      nbPKref=${Record[0]}
      nbPKumap=${Record[1]}
      test=${Record[2]}
      #test='moins'

      # on teste
      if [[ $test == "pareil" ]];
        then echo "        secteur $secteur  ok : $nbPKref PK"
      elif [[ $test == "plus" ]];
        then echo "        secteur $secteur  >>>> problème : " $((nbPKumap - $nbPKref)) " PK en trop"
      elif [[ $test == "moins" ]];
        then echo "        secteur $secteur  >>>> problème : " $((nbPKref - $nbPKumap)) " PK en moins"
      fi

    done

  # fin de la boucle
done


# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
echo ""
echo ""
echo "    2 : si replacement : test de distance"
echo ""


# ici une requête PostGIS sortira les PK qui auront été trop déplacés

read nb_pk_deplaces <<< $( $PSQL -h $DB_HOST -U $DB_USER -d $DB_NAME --no-align -t --quiet -c \
  "SELECT COUNT(*)
  FROM phase_5_pk_ref r FULL JOIN phase_5_pk_umap u ON r.pk_id = u.pk_id 
  WHERE TRUNC(ST_Distance(r.the_geom, u.the_geom)::numeric,2) > 1 ;"
)

echo "        $nb_pk_deplaces PK déplacés manuellement"


# plus de détails
#--no-align -t --quiet --single-transaction --set AUTOCOMMIT=off --set ON_ERROR_STOP=on --field-separator ' ' \

$PSQL -X -h $DB_HOST -U $DB_USER -d $DB_NAME \
-c "WITH liste_pk_decales AS (
  SELECT
   r.pk_id,
   r.secteur_id,
   TRUNC(ST_Distance(r.the_geom, u.the_geom)::numeric,2) as distance
  FROM phase_5_pk_ref r FULL JOIN phase_5_pk_umap u ON r.pk_id = u.pk_id 
  WHERE TRUNC(ST_Distance(r.the_geom, u.the_geom)::numeric,2) > 1
)
      SELECT '1' as tri, '> 1000' as distance, COUNT(*) FROM liste_pk_decales WHERE (distance >= 1000)
UNION SELECT '2' as tri, '>  500' as distance, COUNT(*) FROM liste_pk_decales WHERE (distance >= 500 AND distance < 1000)
UNION SELECT '3' as tri, '>  100' as distance, COUNT(*) FROM liste_pk_decales WHERE (distance >= 100 AND distance < 500)
UNION SELECT '4' as tri, '>   10' as distance, COUNT(*) FROM liste_pk_decales WHERE (distance >= 10 AND distance < 100)
UNION SELECT '5' as tri, '<   10' as distance, COUNT(*) FROM liste_pk_decales WHERE (distance < 10)
ORDER BY tri ;" \
    --single-transaction \
    --set AUTOCOMMIT=off \
    --set ON_ERROR_STOP=on \
    --no-align \
    -t \
    --field-separator ' ' \
    --quiet | 
while read tri distance count ; do
    printf "          $distance $count \n"
done



echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Application des traitements SQL phase 5"
echo ""

$PSQL -h $DB_HOST -U $DB_USER -d $DB_NAME  < traitements_phase_5.sql

echo "  fait"
echo ""





# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#  et on exporte en geojson pour umap et merour

echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Exports"
echo ""

echo "  exports geojson"
echo ""

rm data/phase_5_pk.geojson
ogr2ogr -f "GeoJSON" data/phase_5_pk.geojson PG:"host=$DB_HOST user=redadeg password=redadeg dbname=redadeg" phase_5_pk -sql "SELECT * FROM phase_5_pk ORDER BY pk_id"

echo "  fait"
echo ""

echo "  pousse vers serveur"
echo ""

rsync -av -z data/phase_5_pk.geojson breizhpovh2:/data/www/vhosts/ar-redadeg_openstreetmap_bzh/htdocs/scripts/data/

echo ""
echo "  fait"
echo ""


echo ""
echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  F I N"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo ""
