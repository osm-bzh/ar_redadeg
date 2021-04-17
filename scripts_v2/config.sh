#! /bin/bash


# argument 1 passé au script = millesime redadeg
millesime=$1


# configuration des infos de connexions aux bases de données
# >>>> pas besoin de mettre ces infos dans le .pgpass <<<<<

# chemin vers psql (en cas de multi-versions sur la machine)
PSQL=/usr/bin/psql

# penser à mettre les permissions au rôle redadeg sur la base osm

# BD Ar Redadeg
DB_HOST=localhost
DB_PORT=5432
DB_NAME=redadeg_$millesime
DB_USER=redadeg
DB_PASSWD=redadeg

# BD OSM
osmDBHost=localhost
osmDBPort=5432
osmDBName=osm
osmDBSchema=public
osmDBUser=redadeg
osmDBPassword=redadeg

