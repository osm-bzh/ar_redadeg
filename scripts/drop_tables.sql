/*

SELECT 'DROP TABLE ' || TABLE_NAME || ' CASCADE ;' AS SQL
FROM information_schema.tables 
WHERE
  table_schema = 'public' 
  AND table_type = 'BASE TABLE'
  AND TABLE_NAME NOT IN ('geography_columns','geometry_columns','raster_columns','raster_overviews','spatial_ref_sys')
ORDER BY TABLE_NAME

*/


DROP TABLE osm_communes CASCADE ;
DROP TABLE osm_roads CASCADE ;
DROP TABLE osm_roads_pgr CASCADE ;
DROP TABLE osm_roads_pgr_patch CASCADE ;
DROP TABLE osm_roads_pgr_patch_mask CASCADE ;
DROP TABLE phase_1_pk_vip CASCADE ;
DROP TABLE phase_1_pk_vip_3857 CASCADE ;
DROP TABLE phase_1_trace CASCADE ;
DROP TABLE phase_1_trace_3857 CASCADE ;
DROP TABLE phase_1_trace_4326 CASCADE ;
DROP TABLE phase_1_trace_troncons CASCADE ;
DROP TABLE phase_2_pk_secteur CASCADE ;
DROP TABLE phase_2_pk_secteur_3857 CASCADE ;
DROP TABLE phase_2_point_nettoyage CASCADE ;
DROP TABLE phase_2_point_nettoyage_3857 CASCADE ;
DROP TABLE phase_2_trace_pgr CASCADE ;
DROP TABLE phase_2_trace_secteur CASCADE ;
DROP TABLE phase_2_trace_troncons CASCADE ;
DROP TABLE phase_2_trace_trous CASCADE ;
DROP TABLE phase_3_pk_auto CASCADE ;
DROP TABLE phase_3_pk_sens_verif CASCADE ;
DROP TABLE phase_3_trace_secteurs CASCADE ;
DROP TABLE phase_3_trace_troncons CASCADE ;
DROP TABLE phase_5_pk CASCADE ;
DROP TABLE phase_5_pk_ref CASCADE ;
DROP TABLE phase_5_pk_umap CASCADE ;
DROP TABLE phase_5_pk_umap_4326 CASCADE ;
DROP TABLE secteur CASCADE ;
