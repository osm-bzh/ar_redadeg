


-- on vide puis on remplit à nouveau la couche finale des PK
TRUNCATE phase_5_pk ;

-- pour le moment avec les données de référence
INSERT INTO phase_5_pk
SELECT 
  r.pk_id,
  r.pk_x,
  r.pk_y,
  r.pk_long,
  r.pk_lat,
  r.length_real,
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
  r.the_geom
FROM phase_5_pk_ref r FULL JOIN phase_5_pk_umap u ON r.pk_id = u.pk_id
WHERE u.pk_id IS NOT NULL
ORDER BY r.pk_id ;

