#!/bin/bash



./traitements_phase_1.sh

./create_osm_roads.sh

./update_osm_roads_pgr.sh

#./update_server_routing_tables.sh

./traitements_phase_2.sh



