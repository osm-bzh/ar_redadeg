

## Installation

### Création d'un environnement virtuel python

```bash
cd script_v3
python -m venv .venv
source .venv/bin/activate
pip install psycopg2-binary sqlalchemy pandas
```

## Création d'un millésime

```bash
python setup.py --millesime 2025                                                              [±master ●●]

    _           ____          _           _            
   / \   _ __  |  _ \ ___  __| | __ _  __| | ___  __ _ 
  / _ \ | '__| | |_) / _ \/ _` |/ _` |/ _` |/ _ \/ _` |
 / ___ \| |    |  _ <  __/ (_| | (_| | (_| |  __/ (_| |
/_/   \_\_|    |_| \_\___|\__,_|\__,_|\__,_|\___|\__, |
                                                 |___/ 
    

ATTENTION : la base de données redadeg_2025 va être supprimée !
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

