

/*
==========================================================================

    phase 1 : récupération des données depuis umap et calcul des PK auto

==========================================================================
*/

-- voir la documentation pour la création de la base de données

-- on est obligé de créer des tables en Lambert 93 (EPSG:2154) (ou une CC conforme)
-- car même si les tables originales sont déclarées en 3857
-- en fait les géoémtries sont en 4326
-- donc les calculs de longueur sont faux
-- au moins en créant une table en dur en Lambert 93 / 2154 on est sûr des longueurs


-- la table secteur gère les grands découpage de gestion
DROP TABLE IF EXISTS secteur CASCADE ;
CREATE TABLE secteur
(
  id integer,
  nom_br text,
  nom_fr text,
  longueur_km integer,
  longueur integer,
  longueur_km_redadeg integer,
  node_start integer,
  node_stop integer,
  pk_start integer,
  pk_stop integer,
  CONSTRAINT secteur_pkey PRIMARY KEY (id)
);
ALTER TABLE secteur OWNER to redadeg;



DROP TABLE IF EXISTS phase_1_trace_3857 ;
CREATE TABLE phase_1_trace_3857
(
    fake_column integer
);
ALTER TABLE phase_1_trace_3857 OWNER to redadeg;

DROP TABLE IF EXISTS phase_1_pk_vip_3857 ;
CREATE TABLE phase_1_pk_vip_3857
(
    fake_column integer
);
ALTER TABLE phase_1_pk_vip_3857 OWNER to redadeg;



DROP TABLE IF EXISTS phase_1_trace CASCADE ;
CREATE TABLE phase_1_trace
(
    ogc_fid integer,
    secteur_id int,
    ordre int,
    longueur numeric,
    the_geom geometry(LineString,2154),
    CONSTRAINT phase_1_trace_pkey PRIMARY KEY (ogc_fid),
    CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'LINESTRING'::text),
    CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 2154)
);
CREATE INDEX sidx_phase_1_trace_the_geom ON public.phase_1_trace USING gist (the_geom);
ALTER TABLE phase_1_trace OWNER to redadeg;


DROP TABLE IF EXISTS phase_1_pk_vip CASCADE ;
CREATE TABLE phase_1_pk_vip
(
    ogc_fid integer,
    name text,
    description text,
    the_geom geometry(Point,2154),
    CONSTRAINT phase_1_pk_vip_pkey PRIMARY KEY (ogc_fid),
    CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'POINT'::text),
    CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 2154)
);
CREATE INDEX sidx_phase_1_pk_vip_the_geom ON public.phase_1_pk_vip USING gist (the_geom);
ALTER TABLE phase_1_pk_vip OWNER to redadeg;


-- on crée aussi une version correcte en 4326 pour export vers umap
DROP TABLE IF EXISTS phase_1_trace_4326 ;
CREATE TABLE phase_1_trace_4326
(
    ogc_fid integer,
    name text, -- = section_nom
    secteur_id int,
    ordre int,
    longueur numeric,
    the_geom geometry(LineString,4326),
    CONSTRAINT phase_1_trace_4326_pkey PRIMARY KEY (ogc_fid),
    CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'LINESTRING'::text),
    CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 4326)
);
CREATE INDEX sidx_phase_1_trace_4326_the_geom ON public.phase_1_trace_4326 USING gist (the_geom);
ALTER TABLE phase_1_trace_4326 OWNER to redadeg;


-- table des tronçons créés à partir des longs tracés
DROP TABLE IF EXISTS phase_1_trace_troncons CASCADE ;
CREATE TABLE phase_1_trace_troncons
(
    uid bigint,
    secteur_id int,
    ordre bigint,
    km bigint,
    km_reel bigint,
    longueur integer,
    the_geom geometry(LineString,2154),
    CONSTRAINT phase_1_trace_troncons_pkey PRIMARY KEY (uid),
    CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'LINESTRING'::text),
    CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 2154)
);
CREATE INDEX sidx_phase_1_trace_troncons_the_geom ON public.phase_1_trace_troncons USING gist (the_geom);
ALTER TABLE phase_1_trace_troncons OWNER to redadeg;



-- vue des PK auto en fin de tronçon
DROP VIEW IF EXISTS phase_1_pk_auto ;
CREATE VIEW phase_1_pk_auto AS
  SELECT
    uid, secteur_id, ordre, km, km_reel,
    ST_Line_Interpolate_Point(the_geom, 1)::geometry(Point, 2154) AS the_geom
  FROM phase_1_trace_troncons
  ORDER BY secteur_id ASC, ordre ASC, km ASC ;
ALTER TABLE phase_1_pk_auto OWNER to redadeg;

-- la même mais en 4326 pour export
DROP VIEW IF EXISTS phase_1_pk_auto_4326 ;
CREATE VIEW phase_1_pk_auto_4326 AS
  SELECT
     uid, secteur_id, ordre, km, km_reel,
     ST_Transform(the_geom,4326)::geometry(Point, 4326) AS the_geom
  FROM phase_1_pk_auto
  ORDER BY secteur_id ASC, ordre ASC, km ASC ;
ALTER TABLE phase_1_pk_auto_4326 OWNER to redadeg;

-- vue tableau de bord de synthèse
DROP VIEW IF EXISTS phase_1_tdb ;
CREATE VIEW phase_1_tdb AS
  SELECT
    t.secteur_id, s.nom_br, s.nom_fr,
    TRUNC( SUM(t.longueur)::numeric , 3) AS longueur_km,
    ROUND( SUM(t.longueur)::numeric ) AS longueur_km_arrondi
  FROM phase_1_trace t JOIN secteur s ON t.secteur_id = s.id
  GROUP BY secteur_id, nom_br, nom_fr
  ORDER BY secteur_id ;
ALTER TABLE phase_1_tdb OWNER to redadeg;




/*
==========================================================================

    phase 2 : calcul d'itinéraires en appui du réseau routier OSM

==========================================================================
*/

-- les couches PK venant de umap

DROP TABLE IF EXISTS phase_2_pk_secteur_3857 ;
CREATE TABLE phase_2_pk_secteur_3857
(
    fake_column integer
);
ALTER TABLE phase_2_pk_secteur_3857 OWNER to redadeg;

DROP TABLE IF EXISTS phase_2_point_nettoyage_3857 ;
CREATE TABLE phase_2_point_nettoyage_3857
(
    fake_column integer
);
ALTER TABLE phase_2_point_nettoyage_3857 OWNER to redadeg;


-- la couche des points pour nettoyer la couche de routage
DROP TABLE IF EXISTS phase_2_point_nettoyage CASCADE ;
CREATE TABLE phase_2_point_nettoyage
(
  id serial,
  pt_id bigint,
  edge_id bigint,
  secteur_id integer,
  distance numeric,
  the_geom geometry,
  CONSTRAINT phase_2_point_nettoyage_pkey PRIMARY KEY (id),
  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'POINT'::text),
  CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 2154)
);
CREATE INDEX sidx_phase_2_point_nettoyage_the_geom ON public.phase_2_point_nettoyage USING gist (the_geom);
ALTER TABLE phase_2_point_nettoyage OWNER to redadeg;



DROP TABLE IF EXISTS phase_2_pk_secteur CASCADE ;
CREATE TABLE phase_2_pk_secteur
(
    id integer,
    name text,
    pgr_node_id integer,
    secteur_id integer,
    the_geom geometry(Point,2154),
    CONSTRAINT phase_2_pk_secteur_pkey PRIMARY KEY (id),
    CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'POINT'::text),
    CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 2154)
);
CREATE INDEX sidx_phase_2_pk_secteur_the_geom ON public.phase_2_pk_secteur USING gist (the_geom);
ALTER TABLE phase_2_pk_secteur OWNER to redadeg;


-- une vue en 4326 pour export
DROP VIEW IF EXISTS phase_2_pk_secteur_4326 CASCADE ;
CREATE VIEW phase_2_pk_secteur_4326 AS
  SELECT
    pk.id, pk.name, s.id AS secteur_id, replace(s.nom_fr,' ','') AS nom_fr, replace(s.nom_br,' ','') AS nom_br,
    ST_Transform(pk.the_geom,4326)::geometry(Point, 4326) AS the_geom
  FROM phase_2_pk_secteur pk JOIN secteur s ON pk.id = s.id
  ORDER BY pk.id ;
ALTER TABLE phase_2_pk_secteur_4326 OWNER to redadeg;


-- la couche des communes source OSM
DROP TABLE IF EXISTS osm_communes CASCADE ;
CREATE TABLE osm_communes
(
    insee character varying(5),
    name_fr text,
    name_br text,
    the_geom geometry,
    CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'POLYGON'::text OR geometrytype(the_geom) = 'MULTIPOLYGON'::text),
    CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 2154),
    CONSTRAINT osm_communes_pkey PRIMARY KEY (insee)
);
CREATE INDEX sidx_osm_communes_the_geom ON osm_communes USING gist(the_geom);
ALTER TABLE osm_communes OWNER to redadeg;



-- la couche qui contient les lignes des routes venant de OSM
DROP TABLE IF EXISTS osm_roads CASCADE ;
CREATE TABLE osm_roads
(
  secteur_id integer,
  osm_id bigint,
  highway text,
  type text,
  oneway text,
  ref text,
  name_fr text,
  name_br text,
  the_geom geometry,
  topo_geom topology.topogeometry
  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'LINESTRING'::text OR geometrytype(the_geom) = 'MULTILINESTRING'::text),
  CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 2154)
);
CREATE INDEX osm_roads_geom_idx ON osm_roads USING gist(the_geom);
ALTER TABLE osm_roads OWNER to redadeg;
-- cette couche supporte une topologie
-- SELECT topology.DropTopology('osm_roads_topo');
SELECT topology.CreateTopology('osm_roads_topo', 2154);
SELECT topology.AddTopoGeometryColumn('osm_roads_topo', 'public', 'osm_roads', 'topo_geom', 'LINESTRING');


-- la couche en version routable
DROP TABLE IF EXISTS osm_roads_pgr CASCADE ;
CREATE TABLE osm_roads_pgr
(
  id serial,
  secteur_id integer,
  osm_id bigint,
  highway text,
  type text,
  oneway text,
  ref text,
  name_fr text,
  name_br text,
  source bigint,
  target bigint,
  cost double precision,
  reverse_cost double precision,
  the_geom geometry,
  CONSTRAINT osm_roads_pgr_pkey PRIMARY KEY (id),
  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'LINESTRING'::text OR geometrytype(the_geom) = 'MULTILINESTRING'::text),
  CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 2154)
);
CREATE INDEX osm_roads_pgr_source_idx ON osm_roads_pgr (source);
CREATE INDEX osm_roads_pgr_target_idx ON osm_roads_pgr (target);
CREATE INDEX osm_roads_pgr_geom_idx ON osm_roads_pgr USING gist(the_geom);
ALTER TABLE osm_roads_pgr OWNER to redadeg;



-- couche de polygones pour supprimer le contenu de osm_roads_pgr pour la gestion des boucles
DROP TABLE IF EXISTS osm_roads_pgr_patch_mask CASCADE ;
CREATE TABLE osm_roads_pgr_patch_mask
(
  id serial,
  secteur_id integer,
  name text,
  the_geom geometry,
  CONSTRAINT osm_roads_pgr_patch_mask_pkid PRIMARY KEY (id),
  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'POLYGON'::text),
  CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 2154)
);
CREATE INDEX osm_roads_pgr_patch_mask_geom_idx ON osm_roads_pgr_patch_mask USING gist(the_geom);
ALTER TABLE osm_roads_pgr_patch_mask OWNER to redadeg;


-- couche jumelle de osm_roads mais avec des lignes gérées à la main pour les boucles
DROP TABLE IF EXISTS osm_roads_pgr_patch CASCADE ;
CREATE TABLE osm_roads_pgr_patch
(
  id serial,
  secteur_id integer,
  osm_id bigint,
  highway text,
  type text,
  oneway text,
  ref text,
  name_fr text,
  name_br text,
  source bigint,
  target bigint,
  cost double precision,
  reverse_cost double precision,
  the_geom geometry,
  CONSTRAINT osm_roads_pgr_patch_pkey PRIMARY KEY (id),
  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'LINESTRING'::text OR geometrytype(the_geom) = 'MULTILINESTRING'::text),
  CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 2154)
);
CREATE INDEX osm_roads_pgr_patch_geom_idx ON osm_roads_pgr_patch USING gist(the_geom);
ALTER TABLE osm_roads_pgr_patch OWNER to redadeg;
-- la séquence doit commencer à un chiffre supérieur à 1 car sinon ça fiche la pagaille sur le calcul de routage
ALTER SEQUENCE osm_roads_pgr_patch_id_seq START WITH 1000 ;



-- la table qui va recevoir le résultat du calcul d'itinéraire
DROP TABLE IF EXISTS phase_2_trace_pgr CASCADE ;
CREATE TABLE phase_2_trace_pgr
(
  secteur_id integer,
  -- info de routage
  path_seq bigint,
  node bigint,
  cost double precision,
  agg_cost double precision,
  -- info OSM
  osm_id bigint,
  highway text,
  type text,
  oneway text,
  ref text,
  name_fr text,
  name_br text,
  the_geom geometry,
  CONSTRAINT phase_2_trace_pgr_pkey PRIMARY KEY (secteur_id, path_seq, node),
  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'LINESTRING'::text OR geometrytype(the_geom) = 'MULTILINESTRING'::text),
  CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 2154)
);
CREATE INDEX phase_2_trace_pgr_geom_idx ON phase_2_trace_pgr USING gist(the_geom);
ALTER TABLE phase_2_trace_pgr OWNER to redadeg;

-- une vue en 4326 pour export
DROP VIEW IF EXISTS phase_2_trace_pgr_4326 ;
CREATE VIEW phase_2_trace_pgr_4326 AS
  SELECT
    secteur_id,
    path_seq, node, cost, agg_cost,
    osm_id, highway, type, oneway, ref, name_fr, name_br,
    ST_Transform(the_geom,4326)::geometry(LineString, 4326) AS the_geom
  FROM phase_2_trace_pgr ;
ALTER TABLE phase_2_trace_pgr_4326 OWNER to redadeg;



-- couche qui contient 1 ligne par secteur
DROP TABLE IF EXISTS phase_2_trace_secteur CASCADE ;
CREATE TABLE phase_2_trace_secteur
(
    secteur_id int,
    nom_fr text,
    nom_br text,
    longueur int,
    longueur_km numeric,
    the_geom geometry,
    CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 2154)
);
CREATE INDEX phase_2_trace_secteur_geom_idx ON phase_2_trace_secteur USING gist(the_geom);
ALTER TABLE phase_2_trace_secteur OWNER to redadeg;

-- une vue en 4326 pour export
DROP VIEW IF EXISTS phase_2_trace_secteur_4326 ;
CREATE VIEW phase_2_trace_secteur_4326 AS
  SELECT
    secteur_id, nom_fr, nom_br,
    longueur, longueur_km,
    ST_Transform(the_geom,4326)::geometry(MultiLineString, 4326) AS the_geom
  FROM phase_2_trace_secteur ;
ALTER TABLE phase_2_trace_secteur_4326 OWNER to redadeg;


-- ça sert à quoi ça ?
DROP TABLE IF EXISTS phase_2_trace_trous CASCADE ;
CREATE TABLE phase_2_trace_trous
(
  id serial,
  secteur_id int,
  the_geom geometry,
  CONSTRAINT phase_2_trace_trous_pkid PRIMARY KEY (id),
  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'POINT'::text),
  CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 2154)
);
ALTER TABLE phase_2_trace_trous OWNER to redadeg;







-- la table qui va contenir des tronçons de x m
DROP TABLE IF EXISTS phase_2_trace_troncons CASCADE ;
CREATE TABLE phase_2_trace_troncons
(
  uid serial,
  secteur_id int,
  ordre bigint,
  km bigint,
  km_reel bigint,
  longueur integer,
  -- info OSM
  osm_id bigint,
  highway text,
  type text,
  oneway text,
  ref text,
  name_fr text,
  name_br text,
  the_geom geometry,
  CONSTRAINT phase_2_trace_troncons_pkey PRIMARY KEY (uid),
  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'LINESTRING'::text),
  CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 2154)
);
CREATE INDEX phase_2_trace_troncons_geom_idx ON phase_2_trace_troncons USING gist(the_geom);
ALTER TABLE phase_2_trace_troncons OWNER to redadeg;


-- une vue en 4326 pour export
DROP VIEW IF EXISTS phase_2_trace_troncons_4326 ;
CREATE VIEW phase_2_trace_troncons_4326 AS
  SELECT
    uid, secteur_id, ordre, km_reel, longueur,
    osm_id, highway, type, oneway, ref,
    name_fr, name_br,
    ST_Transform(the_geom,4326)::geometry(LineString, 4326) AS the_geom
  FROM phase_2_trace_troncons ;
ALTER TABLE phase_2_trace_troncons_4326 OWNER to redadeg;




DROP VIEW IF EXISTS phase_2_tdb ;
CREATE VIEW phase_2_tdb AS
    WITH total AS
    (
      SELECT
        0 AS secteur_id, 'Total' AS nom_fr, 'Hollad' AS nom_br,
        SUM(longueur_km) AS longueur_km
      FROM public.phase_2_trace_secteur
      GROUP BY 1
    )
      SELECT 
        a.secteur_id, a.nom_fr, a.nom_br,
        a.longueur_km,
        -- b.km_reels AS longueur_km_attendu, << vérifier si ça sert
        -- -(b.km_reels - a.longueur_km) AS difference, << vérifier si ça sert
        TRUNC(a.longueur_km / (SELECT longueur_km FROM total) * 2020, 0) AS nb_km_redadeg
        --TRUNC((a.longueur_km / (SELECT longueur_km FROM total) * 2020) / b.km_reels, 3) AS longueur_km_redadeg
      FROM phase_2_trace_secteur a JOIN secteur b ON a.secteur_id = b.id
      UNION
      SELECT
        0 AS secteur_id, 'Total' AS nom_fr, 'Hollad' AS nom_br,
        SUM(longueur_km) AS longueur_km,
        0
    -- 0,0,0
      FROM public.phase_2_trace_secteur
      GROUP BY 1
      ORDER BY secteur_id ASC ;
ALTER TABLE phase_2_tdb OWNER TO redadeg;




/*
==========================================================================

    phase 3 : calcul des PK auto

==========================================================================
*/


-- la table qui va accueillir une couche support de calcul itinéraire phase 3
DROP TABLE IF EXISTS phase_3_troncons_pgr CASCADE ;
CREATE TABLE phase_3_troncons_pgr
(
  secteur_id integer,
  -- info de routage
  id serial,
  source bigint,
  target bigint,
  cost double precision,
  reverse_cost double precision,
  -- info OSM
  osm_id bigint,
  highway text,
  type text,
  oneway text,
  ref text,
  name_fr text,
  name_br text,
  the_geom geometry,
  --CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'LINESTRING'::text),
  CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 2154)
);
CREATE INDEX phase_3_troncons_pgr_geom_idx ON phase_3_troncons_pgr USING gist(the_geom);
ALTER TABLE phase_3_troncons_pgr OWNER to redadeg;


/*
DROP TABLE IF EXISTS phase_3_troncons CASCADE ;
CREATE TABLE phase_3_troncons
(
  troncon_id bigint,
  secteur_id int,
  the_geom geometry,
  CONSTRAINT phase_3_troncons_pkey PRIMARY KEY (troncon_id),
  --CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'LINESTRING'::text),
  --CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'LINESTRING'::text OR geometrytype(the_geom) = 'MULTILINESTRING'::text),
  CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 2154)
);
CREATE INDEX phase_3_troncons_geom_idx ON phase_3_trace_troncons USING gist(the_geom);
ALTER TABLE phase_3_troncons OWNER TO redadeg;

-- la même couche en 4326
DROP VIEW IF EXISTS phase_3_troncons_4326 ;
CREATE VIEW phase_3_troncons_4326 AS
  SELECT
    troncon_id,
    secteur_id,
    ST_Transform(the_geom,4326) AS the_geom
  FROM phase_3_troncons ;
ALTER TABLE phase_3_troncons_4326 OWNER TO redadeg;
*/


DROP TABLE IF EXISTS phase_3_trace_secteurs CASCADE ;
CREATE TABLE phase_3_trace_secteurs
(
  secteur_id int,
  nom_fr text,
  nom_br text,
  km_reels numeric(8,2),
  the_geom geometry,
  CONSTRAINT phase_3_trace_secteurs_pkey PRIMARY KEY (secteur_id),
  --CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'LINESTRING'::text OR geometrytype(the_geom) = 'MULTILINESTRING'::text),
  --CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'LINESTRING'::text),
  CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 2154)
);
CREATE INDEX phase_3_trace_secteurs_geom_idx ON phase_3_trace_secteurs USING gist(the_geom);
ALTER TABLE phase_3_trace_secteurs OWNER TO redadeg;

-- la même couche en 4326
DROP VIEW IF EXISTS phase_3_trace_secteurs_4326 ;
CREATE VIEW phase_3_trace_secteurs_4326 AS
  SELECT
    secteur_id, nom_fr, nom_br,
    km_reels,
    ST_Transform(the_geom,4326) AS the_geom
  FROM phase_3_trace_secteurs ;
ALTER TABLE phase_3_trace_secteurs_4326 OWNER TO redadeg;



-- la couche des PK calculés automatiquement
DROP TABLE IF EXISTS phase_3_pk CASCADE ;
CREATE TABLE phase_3_pk
(
  pk_id integer,
  pk_x numeric(8,1),
  pk_y numeric(8,1),
  pk_long numeric(10,8),
  pk_lat numeric(10,8),
  length_real integer,
  length_theorical integer,
  length_total integer,
  secteur_id integer,
  municipality_admincode text,
  municipality_postcode text,
  municipality_name_fr text,
  municipality_name_br text,
  way_osm_id bigint,
  way_highway text,
  way_type text,
  way_oneway text,
  way_ref text,
  way_name_fr text,
  way_name_br text,
  the_geom geometry,
  CONSTRAINT phase_3_pk_pkey PRIMARY KEY (pk_id),
  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'POINT'::text),
  CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 2154)
) ;
CREATE INDEX phase_3_pk_geom_idx ON phase_3_pk USING gist(the_geom);
ALTER TABLE phase_3_pk OWNER TO redadeg;


-- la même couche en 4326
DROP VIEW IF EXISTS phase_3_pk_4326 ;
CREATE VIEW phase_3_pk_4326 AS
  SELECT
    pk_id,
    pk_x, pk_y, pk_long, pk_lat,
    length_real, length_total,
    secteur_id,
    municipality_admincode, municipality_postcode,
    municipality_name_fr, municipality_name_br,
    way_osm_id, way_highway, way_type, way_oneway, way_ref,
    way_name_fr, way_name_br,
    ST_Transform(the_geom,4326)::geometry(Point, 4326) AS the_geom
  FROM phase_3_pk 
  ORDER BY pk_id;
ALTER TABLE phase_3_pk_4326 OWNER TO redadeg;


-- couche de lignes simples directes de PK à PK
DROP TABLE IF EXISTS phase_3_pk_sens_verif ;
CREATE TABLE phase_3_pk_sens_verif
(
  secteur_id integer,
  the_geom geometry,
  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'LINESTRING'::text),
  CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 2154)
) ;
CREATE INDEX phase_3_pk_sens_verif_geom_idx ON phase_3_pk_sens_verif USING gist(the_geom);
ALTER TABLE phase_3_pk_sens_verif OWNER TO redadeg;


-- la même couche en 4326
DROP VIEW IF EXISTS phase_3_pk_sens_verif_4326 ;
CREATE VIEW phase_3_pk_sens_verif_4326 AS
  SELECT
    secteur_id,
    ST_Transform(the_geom,4326)::geometry(LineString, 4326) AS the_geom
  FROM phase_3_pk_sens_verif ;
ALTER TABLE phase_3_pk_sens_verif_4326 OWNER TO redadeg;




/*
==========================================================================

    phase 4 : création de la couche des PK à charger dans umap pour la phase 5

==========================================================================
*/


DROP VIEW IF EXISTS phase_4_pk_auto_4326 CASCADE ;
CREATE VIEW phase_4_pk_auto_4326 AS
  SELECT
    pk_id,
    secteur_id,
    ST_Transform(the_geom,4326)::geometry(Point, 4326) AS the_geom
  FROM phase_3_pk_auto ;
ALTER TABLE phase_4_pk_auto_4326 OWNER TO redadeg;




/*
==========================================================================

    phase 5 : gestion manuelle

==========================================================================
*/

-- la table des PK avant modifications manuelles = PK de référence = phase_3_pk_auto
DROP TABLE IF EXISTS phase_5_pk_ref CASCADE ;
CREATE TABLE phase_5_pk_ref
(
  pk_id integer,
  pk_x numeric(8,1),
  pk_y numeric(8,1),
  pk_long numeric(10,8),
  pk_lat numeric(10,8),
  length_real numeric(6,2),
  length_theorical integer,
  length_total integer,
  secteur_id integer,
  municipality_admincode text,
  municipality_postcode text,
  municipality_name_fr text,
  municipality_name_br text,
  way_osm_id bigint,
  way_highway text,
  way_type text,
  way_oneway text,
  way_ref text,
  way_name_fr text,
  way_name_br text,
  the_geom geometry,
  CONSTRAINT phase_5_pk_ref_pkey PRIMARY KEY (pk_id),
  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'POINT'::text),
  CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 2154)
) ;
CREATE INDEX phase_5_pk_ref_geom_idx ON phase_5_pk_ref USING gist(the_geom);
ALTER TABLE phase_5_pk_ref OWNER TO redadeg;

-- on charge cette table avec les données finales de la phase 3
TRUNCATE TABLE phase_5_pk_ref ;
INSERT INTO phase_5_pk_ref SELECT * FROM phase_3_pk_auto ;


-- on définit manuellement la couche avec un type mixte parce qu'on a des lignes dans la couche de points…
DROP TABLE IF EXISTS phase_5_pk_umap_4326 CASCADE ;
CREATE TABLE phase_5_pk_umap_4326
(
  ogc_fid integer,
  pk_id integer,
  secteur_id integer,
  the_geom geometry,
  --CONSTRAINT phase_5_pk_umap_pkey PRIMARY KEY (ogc_fid),
  CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 4326) 
);
ALTER TABLE phase_5_pk_umap_4326 OWNER TO redadeg;

-- la table en 2154 pour travailler
DROP TABLE IF EXISTS phase_5_pk_umap CASCADE ;
CREATE TABLE phase_5_pk_umap
(
  pk_id integer,
  secteur_id integer,
  the_geom geometry,
  CONSTRAINT phase_5_pk_umap_pkey PRIMARY KEY (pk_id),
  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'POINT'::text),
  CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 2154) 
);
CREATE INDEX phase_5_pk_umap_geom_idx ON phase_5_pk_umap USING gist(the_geom);
ALTER TABLE phase_5_pk_umap OWNER TO redadeg;


-- une vue de contrôle par secteur
DROP VIEW IF EXISTS phase_5_pk_diff_secteur ;
CREATE VIEW phase_5_pk_diff_secteur AS
  WITH ref AS (
    SELECT secteur_id, COUNT(pk_id) as ref 
    FROM phase_5_pk_ref
    GROUP BY secteur_id
  ),
  umap AS (
    SELECT secteur_id, COUNT(pk_id) as umap 
    FROM phase_5_pk_umap
    GROUP BY secteur_id
  )
  SELECT
    r.secteur_id,
    r.ref,
    u.umap,
    r.ref - u.umap AS diff,
    CASE
      WHEN r.ref < u.umap THEN 'plus'
      WHEN r.ref > u.umap THEN 'moins'
      WHEN r.ref = u.umap THEN 'pareil'
      ELSE 'problème'
    END AS test
  FROM "ref" r JOIN umap u ON r.secteur_id = u.secteur_id
  ORDER BY r.secteur_id ;

-- une vue de contrôle par PK
DROP VIEW IF EXISTS phase_5_pk_diff ;
CREATE VIEW phase_5_pk_diff AS
  SELECT
    r.secteur_id
    ,r.pk_id
    ,CASE 
      WHEN TRUNC(ST_Distance(r.the_geom, u.the_geom)::numeric,2) > 1 THEN true
      ELSE false
    END AS deplace
    ,TRUNC(ST_Distance(r.the_geom, u.the_geom)::numeric,0) AS distance_droite
  FROM phase_5_pk_ref r JOIN phase_5_pk_umap u ON r.pk_id = u.pk_id
  ORDER BY r.pk_id ;



-- la table finale des PK
DROP TABLE IF EXISTS phase_5_pk CASCADE ;
CREATE TABLE phase_5_pk
(
  pk_id integer,
  pk_x numeric(8,1),
  pk_y numeric(8,1),
  pk_long numeric(10,8),
  pk_lat numeric(10,8),
  length_real numeric(6,2),
  length_theorical integer,
  length_total integer,
  secteur_id integer,
  municipality_admincode text,
  municipality_postcode text,
  municipality_name_fr text,
  municipality_name_br text,
  way_osm_id bigint,
  way_highway text,
  way_type text,
  way_oneway text,
  way_ref text,
  way_name_fr text,
  way_name_br text,
  the_geom geometry,
  CONSTRAINT phase_5_pk_pkey PRIMARY KEY (pk_id),
  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'POINT'::text),
  CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 2154)
) ;
CREATE INDEX phase_5_pk_geom_idx ON phase_5_pk USING gist(the_geom);
ALTER TABLE phase_5_pk OWNER TO redadeg;


-- la table finale du tracé regroupé par secteur
-- pour affichage uniquement
DROP TABLE IF EXISTS phase_5_trace_troncons CASCADE ;
CREATE TABLE phase_5_trace_troncons
(
  troncon_id serial,
  secteur_id int,
  the_geom geometry,
  CONSTRAINT phase_5_trace_troncons_pkey PRIMARY KEY (troncon_id),
  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'LINESTRING'::text OR geometrytype(the_geom) = 'MULTILINESTRING'::text),
  CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 2154)
);
CREATE INDEX phase_5_trace_troncons_geom_idx ON phase_5_trace_troncons USING gist(the_geom);
ALTER TABLE phase_5_trace_troncons OWNER to redadeg;


/*
==========================================================================

    phase 5 : export préfectures

==========================================================================
*/

DROP VIEW IF EXISTS phase_5_prefecture_liste ;
CREATE VIEW phase_5_prefecture_liste AS
  SELECT
    pk_id 
  , substring(municipality_admincode,1,2) AS dpt
  , municipality_admincode AS comm_insee
  , municipality_name_fr AS comm_nom
  , way_ref AS voie_ref
  , way_name_fr AS voie_nom
  FROM phase_5_pk pp 
  ORDER BY pk_id ;




