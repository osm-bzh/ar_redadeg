#!/bin/bash

set -e
set -u

# argument 1 = millesime redadeg
millesime=$1

PSQL=/usr/bin/psql
DB_HOST=localhost
DB_NAME=redadeg_$millesime
DB_USER=redadeg
DB_PASSWD=redadeg


echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Création des tables dans la base de données $DB_NAME"
echo ""
echo ""

# suppression d'abord
psql -h $DB_HOST -U redadeg -d $DB_NAME < drop_tables.sql

# création
psql -h $DB_HOST -U redadeg -d $DB_NAME < create_tables.sql

# initialisation de la table de référence des secteurs pour le millésime
psql -h $DB_HOST -U redadeg -d $DB_NAME < ../data/$millesime/update_infos_secteurs.sql

