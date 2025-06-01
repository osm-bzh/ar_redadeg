
-- table des secteurs
-- id|nom_br|nom_fr|longueur_km|longueur|longueur_km_redadeg|pk_start|pk_stop|node_start|node_stop|

TRUNCATE TABLE public.secteur ;

INSERT INTO public.secteur
(id, nom_br, nom_fr, longueur_km, longueur, longueur_km_redadeg, pk_start, pk_stop, node_start, node_stop)
VALUES
(999, 'test', 'test',                                                       0,      0,       0,    0,    0, 0, 0),
(010, 'Lannuon -> Plijidi', 'Lannion -> Plésidy',                         220, 220000,  716.00,    0,    0, 0, 0),
(020, 'Plijidi -> Pleiber-Krist', 'Plésidy -> Pleiber-Krist',             238, 238000,  716.00,    0,    0, 0, 0),
(030, 'Pleiber-Krist -> Ar Faou', 'Pleiber-Krist -> Ar Faou',             285, 285000,  716.00,    0,    0, 0, 0),
(040, 'Ar Faou -> Lomener', 'Ar Faou -> Lomener',                         300, 300000,  716.00,    0,    0, 0, 0),
(050, 'Enez Groe', 'Enez Groe',                                            36,  36000, 1008.00 ,   0,    0, 0, 0),
(060, 'An Oriant -> Guegon', 'An Oriant -> Guegon',                       202, 202000,  716.00,    0,    0, 0, 0),
(070, 'Guegon -> Sant-Nikolaz-an-Hent', 'Guegon -> Sant-Nikolaz-an-Hent', 286, 286000, 1008.00,    0,    0, 0, 0),
(080, 'Sant-Nikolaz-an-Hent -> Naoned', 'Sant-Nikolaz-an-Hent -> Naoned', 170, 170000, 1008.00,    0,    0, 0, 0),
;
