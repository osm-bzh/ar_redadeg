# OpenStreetMap & Ar Redadeg


## Contexte


[https://ar-redadeg.openstreetmap.bzh](https://ar-redadeg.openstreetmap.bzh/)

But : créer des données de tracés et points kilométriques basé sur le filaire de voie de OpenStreetMap.

Ceci afin d'avoir un tracé le plus précis possible par rapport aux longueurs et de connaître le nom des voies utilisées.

[TODO : décrire le processus depuis umap puis merour. expliquer les limitation (FME)]


## Prérequis

Une machine sous linux ou OS X.

Une base OpenStreetMap au format natif (osm2pgsql) nommée "osm".
Voir [ce script](https://github.com/osm-bzh/osmbr-mapstyle/blob/master/scripts/update_db.sh) qui fait ça très bien. Attention : 18 Go de disque consommé pour grand ouest de la France.

Un serveur PostgreSQL 11 + PostGIS 2.5 + PGrouting 2.6


## Installation

### Installer ogr2ogr

ogr2ogr nous servira pour charger des données dans la base.

ogr2ogr fait partie du paquet 'gdal-bin'

```
sudo apt-get install gdal-bin
ogr2ogr --version
```

### Cloner ce dépôt

On commence par cloner ce dépôt.

Allez où vous voulez sur votre ordinateur, puis :

`git clone https://github.com/osm-bzh/ar_redadeg.git`

Puis on se déplace dans le répertoire

`cd ar_redadeg/scripts/`




### Créer la base de données

Utiliser le script suivant avec un compte linux qui dispose d'un rôle 'superuser' sur la base PostgreSQL

[scripts/create_database.sh](scripts/create_database.sh)

`./create_database.sh`

Il va créer :
* un compte (rôle) redadeg / redadeg
* une base 'redadeg' 
* les extensions postgis, postgis_topology et pgrouting
* et mettre le rôle 'redadeg' en propriétaire de tout ça


Note : l'extension postgis_topology crée forcément un schéma *topology* dans la base de données.

**Rajouter à la main la connexion à la base dans son pgpass !**

`nano ~/.pgpass`

`localhost:5432:redadeg:redadeg:redadeg`



### Créer les tables

On exécute ensuite le scripts SQL qui va créer toutes les tables

`./create_tables.sh`

La table de référence des secteurs est remplie avec le script `update_infos_secteurs.sql`. Modifier appliquer ce script SQL si nécessaire.


### Création du filaire de voies support du routage

#### filaire de voies OSM

`./create_osm_roads.sh`

Opérations effectuées :
* import du tracé phase 1 dans la base OSM
* dans la base OSM : extraction du réseau de voies (couche `planet_osm_line` à proximité du tracé manuel (zone tampon de 25 m) dans une couche `osm_roads`
* chargement de la couche `osm_roads` obtenue dans la base `redadeg`

La durée de cette étape varie selon votre machine : de 5 à 25 minutes…

Mais les données brutes OSM ne sont pas structurées pour pouvoir calculer un itinéraire.


#### filaire de voies OSM routable

`./create_osm_roads_pgr.sh`

Opérations effectuées :
* création d'une topologie à partir de la couche osm_roads. Le résultat est un schéma osm_roads_topo qui contient des tables / couches qui constituent un graphe planaire.
* ajout d'un nouvel attribut géométrique sur la table osm_roads

On a ici juste créé ce qu'il faut pour disposer d'une topologie. Il faut maintenant la calculer.

Opérations effectuées :
* calcul du graphe topologique
* mise à jour de la couche osm_roads_pgr qui sert au routage / au calcul d'itinéraire

#### Patch manuel du filaire de voies

À cause de la configuration des données à certains endroits ou à cause des boucles en centre-ville il est nécessaire de "patcher" le filaire routable brut.
Pour cela il faut :
* dessiner une zone d'emprise dans la couche osm_roads_pgr_patch_mask
* dessiner un nouveau filaire de voie dans la couche osm_roads_pgr_patch
* appliquer le script `psql -h localhost -U redadeg -d redadeg < patch_osm_roads_pgr.sql` 

Ce script va :
1. supprimer les tronçons de voies de la couche osm_roads_pgr intersectés par les polygones de osm_roads_pgr_patch_mask
2. copier les tronçons de voies de la couche osm_roads_pgr_patch dans osm_roads_pgr
3. recalculer la topologie de routage (car la structure du réseau a été modifié à ces endroits)


#### Automatisation

Si besoin de mettre à jour les données depuis une base OSM fraîche, jouer :
* `./create_osm_roads.sh`
* `./update_osm_roads_pgr.sh`
* `psql -h localhost -U redadeg -d redadeg < patch_osm_roads_pgr.sql`


Si juste besoin de recalculer un itinéraire si les données Redadeg change dans la zone tampon des 25 m existante, jouer seulement :
* `./update_osm_roads_pgr.sh`



## Charger et traiter les données

Le principe est de travailler dans le système de projection Lambert93. Les tables / couches dans ce système ne sont pas suffixé. Les tables d'import depuis umap sont suffixées en "_3857" et les tables ou vues d'export sont suffixées en "_4326".

import depuis umap -> traitements -> export vers umap (ou autres)
3857 -> 2154 -> 4326


### Phase 1

`./traitements_phase_1.sh`

* chargement des données depuis la [carte umap phase 1](http://umap.openstreetmap.fr/fr/map/ar_redadeg_2020_phase_1_274091) dans les tables :
	* `phase_1_trace_3857`
	* `phase_1_pk_vip_3857`
* chargement des tables de travail en Lambert 93 : 
	* `phase_1_trace`
	* `phase_1_pk_vip --> ne sert pas au final`
* traitements :
	* La table `phase_1_trace_troncons` est remplie à partir de la couche `phase_1_trace`. Les lignes du tracé sont découpées en tronçons de 1000 m. Mais attention : on repart à zéro à chaque nouvelle section de la couche `phase_1_trace`. Cette couche de points est surtout là pour donner une vague idée du nb de km "vrais".
	* La vue `phase_1_pk_auto` consiste à placer un point à chaque extrémité de chaque ligne de la couche `phase_1_trace_troncons`.
* export en geojson WGS84 pour umap des tables :
	* `phase_1_trace_4326.geojson`
	* `phase_1_pk_auto_4326.geojson`
* export en Excel des tables :
	* `phase_1_pk_auto_4326.xls`


### Phase 2

`./traitements_phase_2.sh`

* chargement des données depuis la [carte umap phase 2](http://umap.openstreetmap.fr/fr/map/ar_redadeg_2020_phase_2_309120) dans les tables :
	* `phase_2_pk_secteur_3857`
	* `phase_2_point_nettoyage_3857`
* traitements :
	* recalage des PK secteurs sur les nœuds de la couche `osm_roads_pgr_vertices_pgr` (sommets de la couche du filaire de voie routable) => chargement de la couche `phase_2_pk_secteur`
	* recalage des points de nettoyage de la même façon => chargement de la couche `phase_2_point_nettoyage`
	* calcul d'un itinéraire pour chaque secteur en utilisant les PK de début (ou fin) de chaque secteur => remplissage de la couche `phase_2_trace_pgr`
	* création de la couche `phase_2_trace_secteur` à partir de `phase_2_trace_pgr`
* export en geojson WGS84 pour umap des tables :
	* `phase_2_pk_secteur.geojson`
	* `phase_2_trace_pgr.geojson`
	* `phase_2_trace_secteur.geojson`
* exports en Excel des tables :
	* `phase_2_tdb.xls`
	* `phase_2_tdb.csv`







