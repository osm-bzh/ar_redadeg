/*
==========================================================================

    phase 2 : calcul d'itinéraires en appui du réseau routier OSM

==========================================================================
*/

-- dans la base redadeg on a chargé la couche osm_roads qui a été calculée
-- à partir de données OSM



-- 1. Préparation des données pour pouvoir utiliser pgRouting

-- on modifie la table osm_roads
ALTER TABLE osm_roads ADD COLUMN source integer ;
ALTER TABLE osm_roads ADD COLUMN target integer ;

-- calcul de la topologie
SELECT pgr_createTopology('osm_roads', 0.000001, 'the_geom', 'osm_id');


