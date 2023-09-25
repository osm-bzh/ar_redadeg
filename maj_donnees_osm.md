# Mise à jour des données OpenStreetMap

Il est important de disposer de données OSM à jour car on s'appuie sur le filaire de voie OSM.

Le script [`update_db_osm.sh`](https://github.com/osm-bzh/ar_redadeg/blob/master/scripts_v2/update_db_osm.sh) permet de mettre à jour les données depuis un dump PBF France entière.

Attention : 18 Go de disque consommé pour la base pour le grand ouest de la France. Plus 5 Go pour les dumps.

Une mise à jour prend environ 45 minutes.


## Prérequis

### pgpass et hosts

Un fichier `.pgpass` contenant les informations de connection à la base :

`db.openstreetmap.local:5432:*:osmbr:****`

Et une entrée dans le fichier `/etc/hosts` pour résoudre `db.openstreetmap.local`. Typiquement, si la base OSM est sur la même machine (et donc en local) :

`127.0.0.1       db.openstreetmap.local`


### Une base de données `osm`

Et donc, une base de données PostGIS `osm` avec un utilisateur `osmbr`.


```sql
CREATE ROLE osmbr NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT LOGIN NOREPLICATION NOBYPASSRLS PASSWORD '****';

CREATE DATABASE osm WITH OWNER = osmbr ENCODING = 'UTF8';
```

Puis dans la base : `CREATE EXTENSION postgis;`


### Un répertoire de travail

```
sudo mkdir -p /data/dumps/
sudo chown {user}:redadeg /data/dumps/
```

### Récupération du polygone d'extraction

```bash
wget -O /data/dumps/poly_extraction_bzh.poly https://raw.githubusercontent.com/osm-bzh/osmbr-mapstyle/master/data/poly_extraction_bzh.poly
```

