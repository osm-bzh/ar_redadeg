


-- vue simple pour les longueurs directe en 3948
SELECT 
  ogc_fid, name, '' AS secteur,
  TRUNC( ST_Length(the_geom)::numeric , 0)  AS longueur_m,
  TRUNC( (ST_Length(the_geom)/1000)::numeric , 3)  AS longueur_km,
  the_geom
FROM phase_1_trace_3948 ;



-- vue simple sur la couche en 3857
SELECT 
  ogc_fid, name, '' AS secteur,
  TRUNC( ST_Length(ST_Transform(the_geom,3857))::numeric , 0)  AS longueur_m,
  TRUNC( (ST_Length(ST_Transform(the_geom,3857))/1000)::numeric , 3)  AS longueur_km,
  the_geom
FROM phase_1_trace ;





-- crée une polyligne qui part de l'origine et qui fait 50 % de la longueur d'origine
DROP VIEW test_line ;
CREATE VIEW test_line AS
  SELECT
  ogc_fid,
  ST_LineSubstring(the_geom, 0.0, 0.5)::geometry(Linestring,4326) AS the_geom,
  TRUNC( ST_Length(ST_Transform(ST_LineSubstring(the_geom, 0.0, 0.5),3948))::numeric , 0)  AS longueur_m
  FROM phase_1_trace_3948
  WHERE ogc_fid = 9 ;

-- et le point terminal
DROP VIEW test_point ;
CREATE VIEW test_point AS
  SELECT
  ogc_fid,
  ST_Line_Interpolate_Point(the_geom, 0.5)::geometry(Point, 3948) AS the_geom
  FROM phase_1_trace_3948
  WHERE ogc_fid = 9 ;



-- sélection simple avec id, géométrie, longueur, nb de sections et coeff pour les fonctions
SELECT 
  ogc_fid,
  TRUNC(ST_Length(the_geom)::numeric,0)  AS longueur,
  TRUNC((ST_Length(the_geom)/1000)::numeric,2) AS nb_sections,
  1 / TRUNC((ST_Length(the_geom)/1000)::numeric,2)::numeric AS part,
  ST_LineMerge(the_geom) AS the_geom
FROM phase_1_trace_3948


-- remplit une table avec l'extraction de 
TRUNCATE phase_1_pk_auto ;
INSERT INTO phase_1_pk_auto
SELECT ogc_fid AS id, ((dp).geom)::geometry(Point,3948) AS the_geom 
FROM
  (
  SELECT ogc_fid, ST_DumpPoints(ST_Segmentize(the_geom, 1000)) AS dp
  FROM phase_1_trace_3948
) AS foo




-- cette vue crée des tronçons de 940 m à partir des longs tracés
DROP VIEW phase_1_trace_troncons_3948 ;
CREATE VIEW phase_1_trace_troncons_3948 AS
SELECT 
    row_number() over() as uid,
    ogc_fid,
    ST_LineSubstring(the_geom, 940.00*n/length,
  CASE
    WHEN 940.00*(n+1) < length THEN 940.00*(n+1)/length
    ELSE 1
  END) AS the_geom
FROM
  (SELECT
     ogc_fid,
     ST_LineMerge(the_geom)::geometry(LineString,3948) AS the_geom,
     ST_Length(the_geom) As length
  FROM phase_1_trace_3948
  ) AS t
CROSS JOIN generate_series(0,10000) AS n
WHERE n*940.00/length < 1 ;

-- et le point terminal
DROP VIEW phase_1_pk_auto_3948 ;
CREATE VIEW phase_1_pk_auto_3948 AS
  SELECT
    uid,
    ST_Line_Interpolate_Point(the_geom, 1)::geometry(Point, 3948) AS the_geom
  FROM phase_1_trace_troncons_3948 ;



-- tableau de synthèse nb km par secteur
SELECT
  secteur_id, secteur_nom_br, secteur_nom_fr,
  SUM(longueur) AS longueur_m,
  TRUNC( SUM(longueur)/1000::numeric , 3) AS longueur_km,
  ROUND( SUM(longueur)/1000::numeric ) AS longueur_km_arrondi
FROM v_phase_1_trace_troncons_3948
GROUP BY secteur_id, secteur_nom_br, secteur_nom_fr
ORDER BY secteur_id ;









SELECT
  st_length(ST_Collect(the_geom)) AS longueur_m,
  ROUND( st_length(ST_Collect(the_geom))::numeric/1000::numeric ) AS longueur_km,
  ST_Collect(the_geom) AS the_geom
FROM phase_2_trace_pgr


  TRUNC( a.cost::numeric , 0) AS longueur_m,
  TRUNC( a.agg_cost::numeric , 0) AS longueur_cumul_m,
  --TRUNC( a.cost::numeric/1000::numeric , 3) AS longueur_km,
  TRUNC( a.agg_cost::numeric/1000::numeric , 3) AS longueur_cumul_km,
  --ROUND( a.cost::numeric/1000::numeric ) AS longueur_km_arrondi,
  ROUND( a.agg_cost::numeric/1000::numeric ) AS longueur_cumul_km_arrondi,







