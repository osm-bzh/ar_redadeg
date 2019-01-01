
-- on est obligé de créer des tables en 3948
-- car même si les tables original sont déclarées en 3857
-- en fait les géoémtries sont en 4326
-- donc les calculs de longueur sont faux
-- au moins en créant une table en dur en 3948 on est sûr des longueurs


DROP TABLE phase_1_trace_3948 ;
CREATE TABLE phase_1_trace_3948
(
    ogc_fid integer,
    name text,
    description text,
    the_geom geometry(LineString,3948),
    CONSTRAINT phase_1_trace_3948_pkey PRIMARY KEY (ogc_fid),
    CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'LINESTRING'::text),
    CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 3948)
);

DROP TABLE phase_1_pk_vip_3948 ;
CREATE TABLE phase_1_pk_vip_3948
(
    ogc_fid integer,
    name text,
    description text,
    the_geom geometry(Point,3948),
    CONSTRAINT phase_1_pk_vip_3948_pkey PRIMARY KEY (ogc_fid),
    CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'POINT'::text),
    CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 3948)
);



-- table des tronçons créés à partir des longs tracés
DROP TABLE phase_1_trace_troncons_3948 ;
CREATE TABLE phase_1_trace_troncons_3948
(
    uid bigint,
    secteur character varying(25),
    km bigint,
    km_reel bigint,
    longueur integer,
    the_geom geometry(LineString,3948),
    CONSTRAINT phase_1_trace_troncons_3948_pkey PRIMARY KEY (uid),
    CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'LINESTRING'::text),
    CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 3948)
);

-- table des PK auto en fin de tronçon
/*DROP TABLE phase_1_pk_auto_3948 ;
CREATE TABLE phase_1_pk_auto_3948
(
    uid bigint,
    secteur character varying(25),
    km bigint,
    km_reel bigint,
    the_geom geometry(Point,3948),
    CONSTRAINT phase_1_pk_auto_3948_pkey PRIMARY KEY (uid),
    CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'POINT'::text),
    CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 3948)
);*/

-- vue des PK auto en fin de tronçon
CREATE VIEW phase_1_pk_auto_3948 AS
  SELECT
    uid, secteur, km, km_reel,
    ST_Line_Interpolate_Point(the_geom, 1)::geometry(Point, 3948) AS the_geom
  FROM phase_1_trace_troncons_3948 ;

-- la même mais en 4326 pour export
--DROP VIEW phase_1_pk_auto_4326 ;
CREATE VIEW phase_1_pk_auto_4326 AS
  SELECT
     uid, secteur, km, km_reel,
     ST_Transform(the_geom,4326)::geometry(Point, 4326) AS the_geom
  FROM phase_1_pk_auto_3948 ;





