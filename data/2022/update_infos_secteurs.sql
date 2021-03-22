
-- id | nom_br | nom_fr | objectif_km | km_redadeg
TRUNCATE TABLE secteur ;
INSERT INTO secteur VALUES (0, 'Rak-loc''han', 'Pré-départ', 0, 0);
INSERT INTO secteur VALUES (100, 'Gwitreg -> Redon', 'Vitré -> Redon', 121, 1000);
INSERT INTO secteur VALUES (200, 'Redon -> Arzal', 'Redon -> Arzal', 198, 1000);
INSERT INTO secteur VALUES (300, 'Arzal -> Kemperle', 'Arzal -> Quimperlé', 227, 1000);
INSERT INTO secteur VALUES (400, 'Kemperle -> Trevarez', 'Quimperlé -> Trevarez', 264, 1000);
INSERT INTO secteur VALUES (500, 'Trevarez -> Daoulaz', 'Trevarez -> Daoulas', 100, 1000);
INSERT INTO secteur VALUES (600, 'Daoulaz -> Montroulez', 'Daoulas -> Morlaix', 170, 1000);
INSERT INTO secteur VALUES (700, 'Montroulez -> Sant-Brieg', 'Morlaix -> Saint-Brieuc', 203, 1000);
INSERT INTO secteur VALUES (800, 'Sant-Brieg -> Mur', 'Saint-Brieuc -> Mur-de-Bretagne', 100, 1000);
INSERT INTO secteur VALUES (900, 'Mur -> Gwened', 'Mur-de-Bretagne -> Vannes', 150, 1000);
INSERT INTO secteur VALUES (999, 'test', 'test', NULL, NULL);
