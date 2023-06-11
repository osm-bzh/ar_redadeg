
-- table des secteurs
-- id|nom_br|nom_fr|longueur_km|longueur|longueur_km_redadeg|pk_start|pk_stop|node_start|node_stop|

TRUNCATE TABLE public.secteur ;

INSERT INTO public.secteur
(id, nom_br, nom_fr, longueur_km, longueur, longueur_km_redadeg, pk_start, pk_stop, node_start, node_stop)
VALUES
(999, 'test', 'test', 0, 0, 0, 0, 0, 0, 0),
(000, 'Rak-loc''han', 'Pré-départ', 0, 0, 0, 0, 0, 0, 0),
(100, 'Beg ar Raz -> Kemperle', 'Pointe du Raz -> Quimperlé',                285, 285000, 1000,    0,  285, 0, 0),
(200, 'Kemperle -> Ar Roc''h Bernez', 'Quimperlé -> La Roche-Bernard',       200, 200000, 1000,  286,  486, 0, 0),
(300, 'Ar Roc''h Bernez -> Gwenvenez', 'La Roche-Bernard -> Guémené-Penfao', 160, 160000, 1000,  487,  647, 0, 0),
(400, 'Gwenvenez -> Pleder', 'Guémené-Penfao -> Plesder',                    160, 160000, 1000,  648,  808, 0, 0),
(500, 'Pleder -> Ploueg-ar-Mor', 'Plesder -> Plouézec',                      149, 149000, 1000,  809,  958, 0, 0),
(600, 'Ploueg-ar-Mor -> Plijidi', 'Plouézec -> Plésidy',                     270, 270000, 1000,  959, 1229, 0, 0),
(700, 'Plijidi -> Landerne', 'Plésidy -> Landerneau',                        275, 275000, 1000, 1230, 1505, 0, 0),
(800, 'Landerne -> Kastell-Paol', 'Landerneau -> Saint-Pol-de-Léon',         160, 160000, 1000, 1506, 1666, 0, 0),
(900, 'Kastell-Paol -> Montroulez', 'Saint-Pol-de-Léon -> Morlaix',           32,  32000, 1000, 1667, 1699, 0, 0)
;
