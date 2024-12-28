
# Installation


## Base

En tant que root sur le serveur :

1. on crée un répertoire `data` à la racine.

```bash
mkdir /data/
```

2. On y clone le dépôt.

```bash
cd /data/
git clone https://github.com/osm-bzh/ar_redadeg.git
```

3. On lance le script d'installation.

```bash
cd /data/ar_redadeg/scripts_v3/installation/
./setup_machine.sh
```

Après cette étape on a un utilisateur `redadeg` qui est sudo et un répertoire `/data/` qui appartient à l'utilisateur `redadeg`. Et les logiciels de base installés.


## PostgreSQL + PostGIS + logiciel géo

```bash
./install_db_and_geotools.sh
```


