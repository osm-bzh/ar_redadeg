#!/bin/sh

dbhost=localhost

# suppression d'abord
psql -h $dbhost -U redadeg -d redadeg < drop_tables.sql

# création
psql -h $dbhost -U redadeg -d redadeg < create_tables.sql

# initialisation de la table de référence des secteurs
psql -h $dbhost -U redadeg -d redadeg < update_infos_secteurs.sql

