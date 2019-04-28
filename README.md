# OpenStreetMap & Ar Redadeg

## Contexte


[https://ar-redadeg.openstreetmap.bzh](https://ar-redadeg.openstreetmap.bzh/)

But : créer des données de tracés et points kilométriques basé sur le filaire de voie de OpenStreetMap.

Ceci afin d'avoir un tracé le plus précis possible par rapport aux longueurs et de connaître le nom des voies utilisées.



## Installation

### Préparer la base de données

Avec un compte administrateur PostgreSQL :
* Créer un rôle 'redadeg'
* Créer une base 'redadeg' et mettre le rôle 'redadeg' en propriétaire

```sql
CREATE USER redadeg WITH LOGIN PASSWORD 'redadeg';
CREATE DATABASE redadeg WITH OWNER = redadeg;
```

Ouvrir une connexion sur la base redadeg, toujours avec un compte administrateur pour installer les extensions :
* postgis
* postgis_topology
* pgrouting (apt install postgresql-11-pgrouting)

```sql
CREATE EXTENSION postgis ;
CREATE EXTENSION postgis_topology;
CREATE EXTENSION pgrouting;

-- permissions
ALTER SCHEMA topology OWNER TO redadeg ;
ALTER TABLE topology.layer OWNER TO redadeg ;
ALTER TABLE topology.topology OWNER TO redadeg ;
```

Si on veut vérifier : `select * from pgr_version()`
(2.6.2)

Note : l'extension postgis_topology crée forcément un schéma *topology* dans la base de données.

On prépare également la connexion à la base dans son pgpass

`nano ~/.pgpass`

`localhost:5432:redadeg:redadeg:redadeg`


### Installer ogr2ogr

ogr2ogr fait partie du paquet 'gdal-bin'

```
sudo apt-get install gdal-bin
ogr2ogr --version
```


### Installer les tables

On commence par cloner ce dépôt

`git clone https://github.com/osm-bzh/ar_redadeg.git`

Puis on se déplace dans le répertoire

`cd ar_redadeg/scripts/`

On exécute le scripts SQL qui va créer toutes les tables

`psql -U redadeg -d redadeg < create_tables.sql`


## Charger et traiter les données

Phase 1

`./traitements_phase_1.sh`


Phase 2

`./traitements_phase_2.sh`




