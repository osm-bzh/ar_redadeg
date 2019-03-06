
-- on est obligé de créer des tables en Lambert 93 (EPSG:2154) (ou une CC conforme)
-- car même si les tables original sont déclarées en 3857
-- en fait les géoémtries sont en 4326
-- donc les calculs de longueur sont faux
-- au moins en créant une table en dur en Lambert 93 / 2154 on est sûr des longueurs


-- la table secteur gère les grands découpage de gestion
DROP TABLE IF EXISTS secteur CASCADE ;
CREATE TABLE secteur
(
    id integer,
    nom_br text,
    nom_fr text
);

ALTER TABLE secteur OWNER to redadeg;

-- et on insert ces données stables
TRUNCATE TABLE secteur ;
INSERT INTO secteur VALUES (1,'Karaez -> Rostren','Carhaix -> Rostrenen');
INSERT INTO secteur VALUES (2,'Rostren -> Plounevez-Moedeg','Rostrenen -> Plounevez-Moedec');
INSERT INTO secteur VALUES (3,'Plounevez-Moedeg -> Montroulez','Plounevez-Moedec -> Morlaix');
INSERT INTO secteur VALUES (4,'Montroulez -> Ar Faou','Morlaix -> Châteauneuf-du-Faou');
INSERT INTO secteur VALUES (5,'Ar Faou -> Kemperle','Châteauneuf-du-Faou -> Quimperlé');
INSERT INTO secteur VALUES (6,'Kemperle -> Redon','Quimperlé -> Redon');
INSERT INTO secteur VALUES (7,'Redon -> Soulvach','Redon -> Soulvach');
INSERT INTO secteur VALUES (8,'Soulvach -> Roazhon','Soulvach -> Rennes');
INSERT INTO secteur VALUES (9,'Roazhon -> Sant-Brieg','Rennes -> Saint-Brieuc');
INSERT INTO secteur VALUES (10,'Sant-Brieg -> Gwengamp','Saint-Brieuc -> Gwengamp');
INSERT INTO secteur VALUES (999,'test','test');


DROP TABLE IF EXISTS phase_1_trace CASCADE ;
CREATE TABLE phase_1_trace
(
    ogc_fid integer,
    name text,
    secteur_id int,
    ordre int,
    longueur numeric,
    the_geom geometry(LineString,2154),
    CONSTRAINT phase_1_trace_pkey PRIMARY KEY (ogc_fid),
    CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'LINESTRING'::text),
    CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 2154)
);

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

ALTER TABLE phase_1_trace OWNER to redadeg;
ALTER TABLE phase_1_trace_4326 OWNER to redadeg;
ALTER TABLE phase_1_pk_vip OWNER to redadeg;
ALTER TABLE phase_1_trace_troncons OWNER to redadeg;

-- table des PK auto en fin de tronçon
/*DROP TABLE phase_1_pk_auto ;
CREATE TABLE phase_1_pk_auto
(
    uid bigint,
    secteur character varying(25),
    km bigint,
    km_reel bigint,
    the_geom geometry(Point,2154),
    CONSTRAINT phase_1_pk_auto_pkey PRIMARY KEY (uid),
    CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'POINT'::text),
    CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 2154)
);*/

-- vue des PK auto en fin de tronçon
DROP VIEW IF EXISTS phase_1_pk_auto ;
CREATE VIEW phase_1_pk_auto AS
  SELECT
    uid, secteur, ordre, km, km_reel,
    ST_Line_Interpolate_Point(the_geom, 1)::geometry(Point, 2154) AS the_geom
  FROM phase_1_trace_troncons
  ORDER BY secteur ASC, ordre ASC, km ASC ;

-- la même mais en 4326 pour export
DROP VIEW IF EXISTS phase_1_pk_auto_4326 ;
CREATE VIEW phase_1_pk_auto_4326 AS
  SELECT
     uid, secteur, ordre, km, km_reel,
     ST_Transform(the_geom,4326)::geometry(Point, 4326) AS the_geom
  FROM phase_1_pk_auto
  ORDER BY secteur ASC, ordre ASC, km ASC ;

ALTER TABLE phase_1_pk_auto OWNER to redadeg;
ALTER TABLE phase_1_pk_auto_4326 OWNER to redadeg;


-- vue tableau de bord de synthèse
DROP VIEW IF EXISTS tdb_secteur_longueur ;
CREATE VIEW tdb_secteur_longueur AS
  SELECT
    secteur_id, secteur_nom_br, secteur_nom_fr,
    SUM(longueur) AS longueur_m,
    TRUNC( SUM(longueur)/1000::numeric , 3) AS longueur_km,
    ROUND( SUM(longueur)/1000::numeric ) AS longueur_km_arrondi
  FROM v_phase_1_trace_troncons
  GROUP BY secteur_id, secteur_nom_br, secteur_nom_fr
  ORDER BY secteur_id ;




