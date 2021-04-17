#! /bin/bash

# exit dès que qqch se passe mal
#set -e
# sortir si "unbound variable"
#set -u


if [ -z "$1" ]
  then
    echo "Pas de millésime en argument --> stop"
    exit 1
fi

# lecture du fichier de configuration
. config.sh



echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Création des tables dans la base de données $DB_NAME"
echo ""
echo ""
echo "  /!\ Toutes les tables dans la base de données $DB_NAME vont être supprimées !!"
echo ""
read -p "  Appuyer sur la touche [Entrée] pour continuer sinon faire ctrl + C pour arrêter."
echo ""


echo "  suppression des tables"
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME < sql/drop_tables.sql

echo ""
echo "  création des tables"
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME < sql/create_tables.sql

echo ""
echo "  initialisation de la table de référence des secteurs pour le millésime"
PGPASSWORD=$DB_PASSWD $PSQL -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME < ../data/$millesime/update_infos_secteurs.sql


echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  F I N"
echo ""
