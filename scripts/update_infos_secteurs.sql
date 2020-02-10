
-- id | nom_br | nom_fr | objectif_km | km_redadeg
TRUNCATE TABLE secteur ;
INSERT INTO secteur VALUES (0, 'Rak-loc''han', 'Pré-départ', 13, 0);
INSERT INTO secteur VALUES (10, 'Karaez -> Rostren', 'Carhaix -> Rostrenen', 93, 819);
INSERT INTO secteur VALUES (20, 'Rostren -> Plounevez-Moedeg', 'Rostrenen -> Plounevez-Moedec', 99, 818);
INSERT INTO secteur VALUES (30, 'Plounevez-Moedeg -> Montroulez', 'Plounevez-Moedec -> Morlaix', 230, 818);
INSERT INTO secteur VALUES (40, 'Montroulez -> Ar Faou', 'Morlaix -> Châteauneuf-du-Faou', 223, 819);
INSERT INTO secteur VALUES (50, 'Ar Faou -> Kemperle', 'Châteauneuf-du-Faou -> Quimperlé', 264, 818);
INSERT INTO secteur VALUES (60, 'Kemperle -> Kamorzh', 'Quimperlé -> Camors', 212, 820);
INSERT INTO secteur VALUES (61, 'Kamorzh -> Redon', 'Camors -> Redon', 122, 927);
INSERT INTO secteur VALUES (70, 'Redon -> Savenneg', 'Redon -> Savenay', 100, 862);
INSERT INTO secteur VALUES (71, 'Savenneg -> Naoned', 'Savenay -> Nantes', 20, 1620);
INSERT INTO secteur VALUES (72, 'Naoned -> Tilheg', 'Nantes -> Teillay', 122, 865);
INSERT INTO secteur VALUES (80, 'Tilheg -> Roazhon', 'Teillay -> Rennes', 58, 935);
INSERT INTO secteur VALUES (90, 'Roazhon -> Dinan', 'Rennes -> Dinan', 215, 925);
INSERT INTO secteur VALUES (91, 'Dinan -> Sant-Brieg', 'Dinan -> Saint-Brieuc', 105, 824);
INSERT INTO secteur VALUES (100, 'Sant-Brieg -> Gwengamp', 'Saint-Brieuc -> Gwengamp', 145, 821);
INSERT INTO secteur VALUES (999, 'test', 'test', NULL, NULL);
