

## Installation

### Prérequis

* Debian ou Ubuntu
* 4 CPU
* 2 Go RAM
* 40 Go disque


### Installation des logiciels

Aller dans le répertoire `installation` et suivre les [instructions](installation/README.md).

### Création d'un environnement virtuel python

```bash
cd script_v3
python -m venv .venv
source .venv/bin/activate
pip install psycopg2-binary sqlalchemy geoalchemy2 pandas geopandas requests
```

## Création d'une base de données pour un millésime

```bash
python setup.py --millesime 2025 --db

    _           ____          _           _            
   / \   _ __  |  _ \ ___  __| | __ _  __| | ___  __ _ 
  / _ \ | '__| | |_) / _ \/ _` |/ _` |/ _` |/ _ \/ _` |
 / ___ \| |    |  _ <  __/ (_| | (_| | (_| |  __/ (_| |
/_/   \_\_|    |_| \_\___|\__,_|\__,_|\__,_|\___|\__, |
                                                 |___/ 
    

ATTENTION : la base de données redadeg_2027 sur redadeg02.bedniverel.bzh va être supprimée !
TOUTES les données seront supprimées !
Voulez-vous continuer ? (oui/non) : oui

Création d'une base de données pour le millésime 2025.
Fermeture des connexions à la base
Base de données redadeg_2025 supprimée avec succès
Base de données redadeg_2025 créée avec succès
Extensions créées avec succès
Schéma redadeg créé avec succès
Permissions appliquées avec succès
Tables crées avec succès

F I N
Temps écoulé : 00:01
```


## Mise à jour du référentiel communal

```bash
python setup.py --millesime 2027 --ref_communal

    _           ____          _           _            
   / \   _ __  |  _ \ ___  __| | __ _  __| | ___  __ _ 
  / _ \ | '__| | |_) / _ \/ _` |/ _` |/ _` |/ _ \/ _` |
 / ___ \| |    |  _ <  __/ (_| | (_| | (_| |  __/ (_| |
/_/   \_\_|    |_| \_\___|\__,_|\__,_|\__,_|\___|\__, |
                                                 |___/ 
    
Le référentiel communal va être implanté.

ATTENTION : le référentiel communal va être mise à jour dans la base redadeg_2027 sur redadeg02.bedniverel.bzh !

Traitement du Geopackage ADMIN EXPRESS
  ✅ le fichier tmp_files/ADE_4-0_GPKG_LAMB93_FXX-ED2026-01-19.gpkg a été trouvé
  Chargement de la couche des communes dans la base de données…
  ✅ fait !

Traitement du fichier open data de Kerofis
  ✅ le fichier tmp_files/kerofis_20250113.csv a été trouvé
  Insertion des données dans la table 'kerofis'...
  ✅ 57300 lignes insérées avec succès dans 'kerofis'

Mise à jour de la table 'communes'
✅ Référentiel communal mis à jour avec succès

F I N
Temps écoulé : 01:02

```


