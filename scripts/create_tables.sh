#!/bin/sh

millesime=2022

PSQL=/usr/bin/psql
DB_HOST=localhost
DB_NAME=redadeg_$millesime


# suppression d'abord
psql -h $DB_HOST -U redadeg -d $DB_NAME < drop_tables.sql

# création
psql -h $DB_HOST -U redadeg -d $DB_NAME < create_tables.sql

# initialisation de la table de référence des secteurs pour le millésime
psql -h $DB_HOST -U redadeg -d $DB_NAME < ../data/$millesime/update_infos_secteurs.sql

