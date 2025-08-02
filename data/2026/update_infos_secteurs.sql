
-- table des secteurs
-- id|nom_br|nom_fr|longueur_km|longueur|longueur_km_redadeg|pk_start|pk_stop|node_start|node_stop|

TRUNCATE TABLE public.secteur ;

INSERT INTO public.secteur
(id, nom_br, nom_fr, longueur_km, longueur, longueur_km_redadeg, pk_start, pk_stop, node_start, node_stop)
VALUES
(999, 'test', 'test',                                                       0,      0,       0,    0,    0, 0, 0),
(100, 'Lannuon -> Plijidi', 'Lannion -> Plésidy',                         219, 219000,     716,    1,  307, 0, 0),
(200, 'Plijidi -> Pleiber-Krist', 'Plésidy -> Pleiber-Krist',             237, 237000,     716,  308,  639, 0, 0),
(300, 'Pleiber-Krist -> Ar Faou', 'Pleiber-Krist -> Ar Faou',             283, 283000,     716,  640, 1036, 0, 0),
(400, 'Ar Faou -> Lomener', 'Ar Faou -> Lomener',                         299, 299000,     716, 1037, 1455, 0, 0),
(500, 'Enez Groe', 'Enez Groe',                                            36,  36000,    1008, 1456, 1491, 0, 0),
(600, 'An Oriant -> Guegon', 'An Oriant -> Guegon',                       201, 201000,     716, 1492, 1773, 0, 0),
(700, 'Guegon -> Sant-Nikolaz-an-Hent', 'Guegon -> Sant-Nikolaz-an-Hent', 285, 285000,    1008, 1774, 2057, 0, 0),
(800, 'Sant-Nikolaz-an-Hent -> Naoned', 'Sant-Nikolaz-an-Hent -> Naoned', 170, 170000,    1008, 2058, 2226, 0, 0);
