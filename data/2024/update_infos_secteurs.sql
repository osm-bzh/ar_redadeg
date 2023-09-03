
-- table des secteurs
-- id|nom_br|nom_fr|longueur_km|longueur|longueur_km_redadeg|pk_start|pk_stop|node_start|node_stop|

TRUNCATE TABLE public.secteur ;

INSERT INTO public.secteur
(id, nom_br, nom_fr, longueur_km, longueur, longueur_km_redadeg, pk_start, pk_stop, node_start, node_stop)
VALUES
(999, 'test', 'test',                                                          0,      0,    0,    0,    0, 0, 0),
(010, 'Rak-loc''han', 'Pré-départ',                                            6,   6000,  620.00,    1,   10, 0, 0),
(100, 'Beg ar Raz -> Kemperle', 'Pointe du Raz -> Quimperlé',                285, 285000,  688.10,   11,  423, 0, 0),
(200, 'Kemperle -> Ar Roc''h Bernez', 'Quimperlé -> La Roche-Bernard',       199, 199000,  731.60,  424,  695, 0, 0),
(300, 'Ar Roc''h Bernez -> Gwenvenez', 'La Roche-Bernard -> Guémené-Penfao', 160, 160000, 1062.20,  696,  846, 0, 0),
(400, 'Gwenvenez -> Pleder', 'Guémené-Penfao -> Plesder',                    159, 159000, 1052.90,  847,  997, 0, 0),
(500, 'Pleder -> Ploueg-ar-Mor', 'Plesder -> Plouézec',                      150, 150000,  955.40,  998, 1154, 0, 0),
(600, 'Ploueg-ar-Mor -> Plijidi', 'Plouézec -> Plésidy',                     271, 271000,  693.00, 1155, 1545, 0, 0),
(700, 'Plijidi -> Landerne', 'Plésidy -> Landerneau',                        276, 276000,  693.50, 1546, 1943, 0, 0),
(800, 'Landerne -> Kastell-Paol', 'Landerneau -> Saint-Pol-de-Léon',         155, 155000,  688.90, 1944, 2168, 0, 0),
(900, 'Kastell-Paol -> Montroulez', 'Saint-Pol-de-Léon -> Morlaix',           37,  37000,  685.20, 2169, 2222, 0, 0)
;
