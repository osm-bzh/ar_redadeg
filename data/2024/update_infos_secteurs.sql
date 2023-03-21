
-- table des secteurs
-- id|nom_br|nom_fr|longueur_km|longueur|longueur_km_redadeg|pk_start|pk_stop|node_start|node_stop|

TRUNCATE TABLE public.secteur ;

INSERT INTO public.secteur
(id, nom_br, nom_fr, longueur_km, longueur, longueur_km_redadeg, pk_start, pk_stop, node_start, node_stop)
VALUES
(999, 'test', 'test', 0, 0, 0, 0, 0, 0, 0),
(000, 'Rak-loc''han', 'Pré-départ', 0, 0, 0, 0, 0, 0, 0),
(100, 'Beg ar Raz -> Kemperle', 'Pointe du Raz -> Quimperlé',                224, 224000, 1000,    0, 224, 0, 0),
(200, 'Kemperle -> Ar Roc''h Bernez', 'Quimperlé -> La Roche-Bernard',       224, 224000, 1000,  225, 449, 0, 0),
(300, 'Ar Roc''h Bernez -> Gwenvenez', 'La Roche-Bernard -> Guémené-Penfao', 224, 224000, 1000,  450, 674, 0, 0),
(400, 'Gwenvenez -> Pleder', 'Guémené-Penfao -> Plesder',                    224, 224000, 1000,  675, 899, 0, 0),
(500, 'Pleder -> Ploueg-ar-Mor', 'Plesder -> Plouézec',                      224, 224000, 1000,  900, 1124, 0, 0),
(600, 'Ploueg-ar-Mor -> Plijidi', 'Plouézec -> Plésidy',                     224, 224000, 1000, 1125, 1349, 0, 0),
(700, 'Plijidi -> Landerne', 'Plésidy -> Landerneau',                        224, 224000, 1000, 1350, 1574, 0, 0),
(800, 'Landerne -> Kastell-Paol', 'Landerneau -> Saint-Pol-de-Léon',         224, 224000, 1000, 1575, 1799, 0, 0),
(900, 'Kastell-Paol -> Montroulez', 'Saint-Pol-de-Léon -> Morlaix',          224, 224000, 1000, 1800, 2024, 0, 0)
;
