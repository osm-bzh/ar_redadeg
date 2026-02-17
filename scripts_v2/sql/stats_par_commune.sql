

-- retourne une table de ce type
/*
pk_min|pk_max|passage_unique|city_code|postal_code|name_br                |name_fr                    |
------+------+--------------+---------+-----------+-----------------------+---------------------------+
     1|    77|non           |22113    |22300      |Lannuon                |Lannion                    |
    27|    29|oui           |22198    |22560      |Pleuveur-Bodoù         |Pleumeur-Bodou             |
    30|    38|oui           |22353    |22730      |Tregastell             |Trégastel                  |
    39|    47|oui           |22168    |22700      |Perroz-Gireg           |Perros-Guirec              |
    48|    54|oui           |22134    |22700      |Louaneg                |Louannec                   |
    55|    58|oui           |22090    |22450      |Kervaria-Sular         |Kermaria-Sulard            |
    59|    60|oui           |22381    |22450      |Trezeni                |Trézény                    |
    61|    68|non           |22265    |22300      |Rospezh                |Rospez                     |
*/

TRUNCATE TABLE communes_stats;

WITH source_data AS (
    SELECT
        MIN(i.pk_id) AS pk_min,
        MAX(i.pk_id) AS pk_max,
        i.code_insee,
        i.code_postal,
        i.name_br,
        i.name_fr
    FROM (
        SELECT c.*, pk.pk_id
        FROM communes c
        JOIN phase_5_pk pk ON ST_Intersects(c.geom, pk.the_geom)
    ) i
    GROUP BY i.code_insee, i.code_postal, i.name_br, i.name_fr
),
ranked_data AS (
    SELECT
        pk_min,
        pk_max,
        code_insee,
        code_postal,
        name_br,
        name_fr,
        LEAD(pk_min) OVER (ORDER BY pk_min) AS next_pk_min
    FROM source_data
)
INSERT INTO public.communes_stats
(pk_min, pk_max, passage_unique, name_fr, name_br, code_insee, code_postal)
SELECT
    pk_min,
    pk_max,
    CASE
        WHEN pk_max > next_pk_min THEN 'non'
        ELSE 'oui'
    END AS passage_unique,
    code_insee,
    code_postal,
    name_br,
    name_fr
FROM ranked_data;
