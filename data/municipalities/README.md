# Données communales issues d'OSM


## Contexte

Il faut utiliser uniquement les données provenant de la base de données OSM car :

* pas de couche communales provenant d'OSM disponible
* il faut le `name:br`

Voir aussi : [https://github.com/osm-bzh/ar_redadeg/issues/1](https://github.com/osm-bzh/ar_redadeg/issues/1)


## Création des données OSM

Créer les tables dans une base de données OpenStreetMap "planet" avec `create_osm_municipalities_tables.sql`.

Créer les données en jouant le script `insert_into_municipalities_polygon.sql`.

Exporter les données avec un backup uniquement sur les tables.


## Import dans une base de données Ar Redadeg

Créer les tables avec `create_osm_municipalities_tables.sql`.

Remonter les données du backup fait à l'étape d'avant.
