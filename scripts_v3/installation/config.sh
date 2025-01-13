#! /bin/bash


# argument 1 passé au script = millesime redadeg
millesime=$1

rep_data=../data/$millesime

# configuration des infos de connexions aux bases de données
# >>>> pas besoin de mettre ces infos dans le .pgpass <<<<<

# chemin vers psql (en cas de multi-versions sur la machine)
PSQL=/usr/bin/psql

# penser à mettre les permissions au rôle redadeg sur la base osm

# BD Ar Redadeg
redadegDBHost=localhost
redadegDBPort=5432
redadegDBName=redadeg_$millesime
redadegDBSchema=public
redadegDBUser=redadeg
redadegDBPassword=betekantrech

#BD OpenStreetMap
osmDBName=osm
