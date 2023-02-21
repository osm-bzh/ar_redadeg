
-- table des secteurs
-- id|nom_br|nom_fr|longueur_km|longueur|longueur_km_redadeg|node_start|node_stop|pk_start|pk_stop|

TRUNCATE TABLE public.secteur ;

INSERT INTO public.secteur
(id, nom_br, nom_fr, longueur_km, longueur, longueur_km_redadeg, node_start, node_stop, pk_start, pk_stop)
VALUES
(999, 'test', 'test', 0, 0, 0, 0, 0, 0, 0),
(000, 'Rak-loc''han', 'Pré-départ',                                    0, 0, 0, 0, 0, 0, 0),
(100, 'Beg ar Raz -> Kemperle', 'Pointe du Raz -> Quimperlé',          0, 0, 0, 0, 0, 0, 0),
(200, 'Kemperle -> Ar Roc''h Bernez', 'Quimperlé -> La Roche-Bernard', 0, 0, 0, 0, 0, 0, 0),
(300, 'Ar Roc''h Bernez -> Plesse', 'La Roche-Bernard -> Plessé',      0, 0, 0, 0, 0, 0, 0),
(400, 'Plesse -> Evrann', 'Plessé -> Évran',                           0, 0, 0, 0, 0, 0, 0),
(500, 'Evrann -> Gwengamp', 'Évran -> Guingamp',                       0, 0, 0, 0, 0, 0, 0),
(600, 'Gwengamp -> Plijidi', 'Guingamp -> Plésidy',                    0, 0, 0, 0, 0, 0, 0),
(700, 'Plijidi -> Landerne', 'Plésidy -> Landerneau',                  0, 0, 0, 0, 0, 0, 0),
(800, 'Landerne -> Kastell-Paol', 'Landerneau -> Saint-Pol-de-Léon',   0, 0, 0, 0, 0, 0, 0),
(900, 'Kastell-Paol -> Montroulez', 'Saint-Pol-de-Léon -> Morlaix',    0, 0, 0, 0, 0, 0, 0)
;
