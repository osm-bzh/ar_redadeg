


-- on vide puis on remplit à nouveau la couche finale des PK
TRUNCATE phase_5_pk ;

-- pour le moment avec les données de référence
INSERT INTO phase_5_pk
SELECT 
  r.pk_id,
  ROUND(ST_X(ST_Transform(u.the_geom,2154))::numeric,1) as pk_x,
  ROUND(ST_Y(ST_Transform(u.the_geom,2154))::numeric,1) as pk_y,
  ST_X(u.the_geom) as pk_long,
  ST_Y(u.the_geom) as pk_lat,
  NULL as length_real,
  r.length_theorical,
  r.secteur_id,
  r.municipality_admincode,
  r.municipality_postcode,
  r.municipality_name_fr,
  r.municipality_name_br,
  r.way_osm_id,
  r.way_highway,
  r.way_type,
  r.way_oneway,
  r.way_ref,
  r.way_name_fr,
  r.way_name_br,
  u.the_geom
FROM phase_5_pk_ref r FULL JOIN phase_5_pk_umap u ON r.pk_id = u.pk_id
WHERE u.pk_id IS NOT NULL
ORDER BY r.pk_id ;


-- on calcule les coordonnées


