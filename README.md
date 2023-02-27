# OpenStreetMap & Ar Redadeg


## Contexte


[https://ar-redadeg.openstreetmap.bzh](https://ar-redadeg.openstreetmap.bzh/)

But : créer des données de tracés et points kilométriques basé sur le filaire de voie de OpenStreetMap.

Ceci afin d'avoir un tracé le plus précis possible par rapport aux longueurs et de connaître le nom des voies utilisées.


## Principes

Ar Redadeg fonctionne par millésime et par secteurs.

TODO


## Prérequis

* Une machine sous linux ou OS X.
* Python > 3.8
* Un serveur PostgreSQL 12.9 + PostGIS 2.5 + PGrouting 3.1
* Une base de données OpenStreetMap au format natif (osm2pgsql) nommée "osm"
* Une base de données "redadeg" par millésime


## Instructions

#### [Installation](installation.md)
#### [Configuration d'un nouveau millésime](configuration_millesime.md)
#### [Traitements](traitements.md)
#### [Mise à jour des données OpenStreetMap](maj_donnees_osm.md)












