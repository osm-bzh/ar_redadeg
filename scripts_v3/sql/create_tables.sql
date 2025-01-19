

/*
==========================================================================

    tables de configuration / gestion

==========================================================================
*/

SET search_path TO redadeg, public;


DROP TABLE IF EXISTS secteurs CASCADE ;
CREATE TABLE secteurs
(
  id integer,
  nom_br text,
  nom_fr text,
  longueur_km integer,
  longueur integer,
  longueur_km_redadeg integer,
  node_start integer,
  node_stop integer,
  pk_start integer,
  pk_stop integer
);
-- commentaires
COMMENT ON TABLE secteurs IS 'Cette table gère les grands découpage de gestion du tracé.';
-- contraintes
ALTER TABLE secteurs ADD CONSTRAINT secteurs_pk PRIMARY KEY (id);
-- permissions
ALTER TABLE secteurs OWNER to redadeg;



DROP TABLE IF EXISTS umap_layers CASCADE ;
CREATE TABLE umap_layers
(
  phase integer,
  secteur integer,
  url text
);
-- commentaires
COMMENT ON TABLE umap_layers IS 'Cette table stocke les identifiants des datalayers des cartes umap.';
-- contraintes
ALTER TABLE umap_layers ADD CONSTRAINT umap_layers_pk PRIMARY KEY (phase, secteur);
-- permissions
ALTER TABLE umap_layers OWNER to redadeg;

