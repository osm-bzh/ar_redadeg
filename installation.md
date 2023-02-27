## Installation

### Cloner ce dépôt

On commence par cloner ce dépôt.

Allez où vous voulez sur votre ordinateur, puis :

`git clone https://github.com/osm-bzh/ar_redadeg.git`


### Installer ogr2ogr

ogr2ogr servira pour charger des données dans la base.

ogr2ogr fait partie du paquet 'gdal-bin'

```
sudo apt-get install gdal-bin
ogr2ogr --version
```

### Python

À partir de la phase 4, on utilise un environnement virtuel Python 3.
Et à terme, tous les scripts seront en python.

Généralités pour Python3 :

```bash
sudo apt install libpq-dev python3-dev
sudo apt install python-is-python3
```

Création d'un environnement virtuel Python pour le projet :

```bash
python -m venv .venv
source .venv/bin/activate

python -m pip install --upgrade pip setuptools
python -m pip install psycopg2 wget
```
