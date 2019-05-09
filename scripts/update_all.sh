#!/bin/bash



./traitements_phase_1.sh


./create_osm_roads.sh
# import du tracé phase 1 dans la base OSM
# extraction du réseau de voies à proximité
# chargement de la couche osm_roads dans la base redadeg


./create_osm_roads_pgr.sh
# à utiliser si on veut complètement recréer un graphe routier à neuf


./update_osm_roads_pgr.sh
# maj des couches de routage


./traitements_phase_2.sh

