
TRUNCATE TABLE redadeg.communes ;

WITH ign AS
(
	SELECT
		  i.code_insee
		, i.code_postal
		, i.nom_officiel AS name_fr
		, i.geom
	FROM redadeg.communes_ign i
	WHERE LEFT(i.code_insee, 2) IN ('22','29','35','44','56')
)
, kerofis AS
(
	SELECT
		  k.kkb_kod_insee::varchar(5) AS code_insee
		, k.kkb_kumun_bre AS name_br
	FROM redadeg.kerofis k
	WHERE k.kr_rummad_bre = 'Kumun'
	GROUP BY k.kkb_kod_insee, k.kkb_kumun_bre
)
INSERT INTO redadeg.communes
	(code_insee, code_postal, name_fr, name_br, geom)
SELECT
	  i.code_insee
	, i.code_postal
	, i.name_fr
	, k.name_br
	, i.geom
FROM ign i
	FULL OUTER JOIN kerofis k ON i.code_insee = k.code_insee
WHERE i.code_insee IS NOT NULL
;