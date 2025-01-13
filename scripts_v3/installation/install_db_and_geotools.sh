#! /bin/bash

# exit dès que qqch se passe mal
# set -e
# on continue même si qqch se passe mal
set +e

echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Installation de PostgreSQL PostGIS PGrouting"
echo ""

apt update
apt install -y postgresql libpq5 postgresql-postgis postgresql-pgrouting

echo ""

echo ""
echo "copie des nouveaux fichiers de conf"
# sauvegarde des fichiers de conf
PGDIR=/etc/postgresql/15/main/
mv "$PGDIR"postgresql.conf "$PGDIR"postgresql.conf~default
mv "$PGDIR"pg_hba.conf "$PGDIR"pg_hba.conf~default
# la conf personnalisée
cp files/pg_hba.conf $PGDIR
cp files/postgresql.conf $PGDIR

echo ""
echo "redémarrage de PostgreSQL"
service postgresql restart


echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Création des rôles PostgreSQL'"
echo ""

su - postgres
psql -c "CREATE ROLE redadeg WITH SUPERUSER INHERIT LOGIN PASSWORD 'betekantrech';"


echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Installation du pgpass'"
echo ""

cp -f pgpass /home/redadeg/.pgpass
chmod 600 /home/redadeg/.pgpass


echo ""
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Installation des paquets géo"
echo ""

apt update

apt install -y gdal-bin osm2pgsql osmctools

