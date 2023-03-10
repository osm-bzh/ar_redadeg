#! /bin/bash

secteur_id=$1

secteur_id_len=${#secteur_id}
if [ $secteur_id_len == 2 ]
then secteur_id_next="$(( ${secteur_id:0:1} + 1 ))0"
elif [ $secteur_id_len == 3 ]
then secteur_id_next="$(( ${secteur_id:0:1} + 1 ))00"
elif [ $secteur_id_len == 4 ]
then secteur_id_next="$(( ${secteur_id:0:1} + 1 ))000"
fi

#secteur_id_next="$(( ${secteur_id:0:1} + 1 )) ${secteur_id_len}"


echo "  Création de la couche osm_roads pour le secteur $secteur_id -> $secteur_id_next"
